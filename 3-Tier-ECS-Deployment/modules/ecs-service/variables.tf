# =============================================================================
# ECS Service Module Variables
# =============================================================================

# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "capacity_provider" {
  description = "Name of the capacity provider"
  type        = string
}

# -----------------------------------------------------------------------------
# Task Definition
# -----------------------------------------------------------------------------

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS execution role"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "wordpress"
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 512

  validation {
    condition     = var.cpu >= 128
    error_message = "CPU must be at least 128 units."
  }
}

variable "memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 1024

  validation {
    condition     = var.memory >= 256
    error_message = "Memory must be at least 256 MB."
  }
}

# -----------------------------------------------------------------------------
# WordPress Configuration
# -----------------------------------------------------------------------------

variable "wordpress_db_host" {
  description = "Database hostname for WordPress"
  type        = string
}

variable "wordpress_db_name" {
  description = "Database name for WordPress"
  type        = string
}

variable "wordpress_db_user" {
  description = "Database username for WordPress"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  type        = string
}

# -----------------------------------------------------------------------------
# Service Configuration
# -----------------------------------------------------------------------------

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 1
    error_message = "Desired count must be at least 1."
  }
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}