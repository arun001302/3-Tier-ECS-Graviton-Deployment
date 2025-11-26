# =============================================================================
# ECS Cluster Module Outputs
# =============================================================================

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "capacity_provider_name" {
  description = "Name of the capacity provider"
  value       = aws_ecs_capacity_provider.main.name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.ecs.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.ecs.latest_version
}