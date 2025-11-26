# =============================================================================
# Security Groups Module Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Port for database connections"
  type        = number
  default     = 3306
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {} 
}