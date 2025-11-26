# =============================================================================
# ALB Module Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}