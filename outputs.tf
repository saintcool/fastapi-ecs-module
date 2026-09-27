output "alb_dns_name" {
  description = "Public DNS name of the ALB fronting the service."
  value       = module.alb.dns_name
}

output "ecr_repository_url" {
  description = "URL of the service's own ECR repository. Push an image here, then run apply again to roll it out."
  value       = module.ecr_repo.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster running the service."
  value       = module.ecs_cluster.name
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = module.service.name
}

output "log_group_name" {
  description = "CloudWatch log group receiving the container's stdout/stderr."
  value       = module.logs.log_group_name
}
