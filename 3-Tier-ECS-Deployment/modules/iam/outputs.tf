# =============================================================================
# IAM Module Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# ECS Execution Role
# -----------------------------------------------------------------------------

output "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.name
}

# -----------------------------------------------------------------------------
# ECS Task Role
# -----------------------------------------------------------------------------

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

output "task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task.name
}

# -----------------------------------------------------------------------------
# EC2 Instance Role
# -----------------------------------------------------------------------------

output "instance_role_arn" {
  description = "ARN of the ECS EC2 instance role"
  value       = aws_iam_role.ecs_instance.arn
}

output "instance_role_name" {
  description = "Name of the ECS EC2 instance role"
  value       = aws_iam_role.ecs_instance.name
}

output "instance_profile_arn" {
  description = "ARN of the ECS EC2 instance profile"
  value       = aws_iam_instance_profile.ecs_instance.arn
}

output "instance_profile_name" {
  description = "Name of the ECS EC2 instance profile"
  value       = aws_iam_instance_profile.ecs_instance.name
}