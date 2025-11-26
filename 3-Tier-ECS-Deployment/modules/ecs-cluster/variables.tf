# =============================================================================
# ECS Cluster Module Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for ECS instances (must be ARM64/Graviton)"
  type        = string
  default     = "t4g.medium"

  validation {
    condition     = can(regex("^(t4g|m6g|m7g|c6g|c7g|r6g|r7g)\\.", var.instance_type))
    error_message = "Instance type must be a Graviton (ARM64) instance type (t4g, m6g, m7g, c6g, c7g, r6g, r7g)."
  }
}

variable "ami_id" {
  description = "AMI ID for ECS instances (ECS-optimized ARM64)"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2

  validation {
    condition     = var.min_instances >= 1
    error_message = "Minimum instances must be at least 1."
  }
}

variable "max_instances" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4

  validation {
    condition     = var.max_instances >= 1
    error_message = "Maximum instances must be at least 1."
  }
}

variable "desired_instances" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS instances"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS instances"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name for ECS instances"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}