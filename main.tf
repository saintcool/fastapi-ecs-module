module "alb_sg" {
  source        = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/ec2/security_group?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name          = "${var.app_name}-alb-sg"
  vpc_id        = var.vpc_id
  ingress_rules = [{ from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP from internet" }]
  egress_rules  = [{ from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "All outbound" }]
}

module "ecs_sg" {
  source        = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/ec2/security_group?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name          = "${var.app_name}-ecs-sg"
  vpc_id        = var.vpc_id
  ingress_rules = [{ from_port = var.container_port, to_port = var.container_port, protocol = "tcp", security_groups = [module.alb_sg.security_group_id], description = "App port from ALB" }]
  egress_rules  = [{ from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"], description = "All outbound" }]
}

module "alb" {
  source             = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/alb/load_balancer?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name               = "${var.app_name}-alb"
  internal           = false
  security_group_ids = [module.alb_sg.security_group_id]
  subnet_ids         = var.public_subnet_ids
}

module "alb_tg" {
  source       = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/alb/target_group?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name         = "${var.app_name}-tg"
  vpc_id       = var.vpc_id
  port         = var.container_port
  protocol     = "HTTP"
  target_type  = "ip"
  health_check = { path = var.health_check_path, port = tostring(var.container_port), interval = 30, healthy_threshold = 2, unhealthy_threshold = 3, matcher = "200" }
}

module "alb_listener" {
  source                          = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/alb/listener?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  load_balancer_arn               = module.alb.arn
  port                            = 80
  protocol                        = "HTTP"
  default_action_type             = "forward"
  default_action_target_group_arn = module.alb_tg.arn
}

module "ecr_repo" {
  source       = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/ecr/repository?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name         = var.app_name
  scan_on_push = true
  force_delete = true
}

module "ecs_cluster" {
  source             = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/ecs/cluster?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name               = "${var.app_name}-cluster"
  container_insights = true
}

module "logs" {
  source            = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/cloudwatch/log_group?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name              = "/ecs/${var.app_name}"
  retention_in_days = var.log_retention_days
}

module "exec_role" {
  source             = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/iam/role?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name               = "${var.app_name}-execution-role"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }] })
}

module "exec_role_policy" {
  source     = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/iam/policy_attachment?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  role_name  = module.exec_role.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

module "task_definition" {
  source                = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/ecs/task_definition?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  family                = var.app_name
  cpu                   = var.cpu
  memory                = var.memory
  execution_role_arn    = module.exec_role.role_arn
  container_definitions = jsonencode([{
    name         = var.app_name
    image        = "${module.ecr_repo.repository_url}:${var.container_image_tag}"
    essential    = true
    portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = module.logs.log_group_name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

module "service" {
  source             = "git::https://github.com/lace-cloud/registry-tf.git//modules/aws/ecs/service?ref=7547263d49c6c9ed8f0842ef3e7bcfdb304769ee"
  name               = var.app_name
  cluster_id         = module.ecs_cluster.id
  task_definition    = module.task_definition.arn
  container_name     = var.app_name
  container_port     = var.container_port
  target_group_arn   = module.alb_tg.arn
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.ecs_sg.security_group_id]
  assign_public_ip   = true
  depends_on         = [module.exec_role_policy]
}
