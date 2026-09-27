variable "app_name" {
  description = "Name of the service. Used to derive resource names (ALB, target group, security groups, task family, log group)."
  type        = string
}

variable "aws_region" {
  description = "AWS region the service is deployed into. Used only for the CloudWatch log configuration on the task."
  type        = string
}

variable "vpc_id" {
  description = "VPC the ALB and ECS service are deployed into."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ECS service tasks."
  type        = list(string)
}

variable "container_port" {
  description = "Port the application container listens on."
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "HTTP path the ALB target group polls for health."
  type        = string
  default     = "/health"
}

variable "container_image_tag" {
  description = "Tag to deploy from the service's own ECR repository."
  type        = string
  default     = "latest"
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch log group retention for the service's container logs."
  type        = number
  default     = 14
}
