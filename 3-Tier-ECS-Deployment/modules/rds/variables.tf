# =============================================================================
# RDS Module Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"

  validation {
    condition     = can(regex("^db\\.", var.instance_class))
    error_message = "Instance class must start with 'db.' prefix."
  }
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "wordpress"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "username" {
  description = "Master username for the database"
  type        = string
  default     = "wpadmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.username))
    error_message = "Username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for DB subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}