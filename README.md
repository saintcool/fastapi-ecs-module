# fastapi-ecs-service

A load-balanced AWS Fargate service: ALB → target group → ECS service, with its
own ECR repository and CloudWatch log group. Extracted from the actual stack
behind `fastapi-ecs-demo` — the nine registry primitives (ALB, target group,
listener, two security groups, ECS cluster, ECS service, task definition, ECR
repository, CloudWatch log group) that any new HTTP-on-ECS service needs,
wired once instead of by hand each time.

## Usage

```hcl
module "api" {
  source  = "lace.cloud/northwind-labs/fastapi-ecs-service/aws"
  version = "1.0.1"

  app_name           = "my-service"
  aws_region         = "us-east-1"
  vpc_id             = "vpc-0123456789abcdef0"
  public_subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  private_subnet_ids = ["subnet-ccc", "subnet-ddd"]
}
```

Push an image to `module.api.ecr_repository_url`, then `lace run apply` again
to roll it out.

## Inputs

| Name | Description | Default |
|---|---|---|
| `app_name` | Service name; derives all resource names | — |
| `aws_region` | Region, used for the log driver config | — |
| `vpc_id` | VPC for the ALB and service | — |
| `public_subnet_ids` | Subnets for the internet-facing ALB | — |
| `private_subnet_ids` | Subnets for the ECS tasks | — |
| `container_port` | App listen port | `8000` |
| `health_check_path` | ALB target group health check path | `/health` |
| `container_image_tag` | Tag to deploy from the service's own ECR repo | `latest` |
| `cpu` / `memory` | Fargate task size | `256` / `512` |
| `log_retention_days` | CloudWatch log retention | `14` |

## Outputs

`alb_dns_name`, `ecr_repository_url`, `ecs_cluster_name`, `ecs_service_name`, `log_group_name`
