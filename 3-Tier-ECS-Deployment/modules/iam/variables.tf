# =============================================================================
# IAM Module Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name for ECS tasks"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}