# =============================================================================
# Root Module Variables
# =============================================================================
# All configurable parameters for the 3-tier Graviton deployment
# =============================================================================

# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  default     = "3-tier-graviton"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Networking Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway to save costs (set false for HA)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Domain and SSL Configuration
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Root domain name (must be hosted in Route53)"
  type        = string
  default     = "architecture-demo.com"
}

variable "subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "wp"
}

# -----------------------------------------------------------------------------
# ECS Configuration
# -----------------------------------------------------------------------------

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS cluster (must be ARM64/Graviton)"
  type        = string
  default     = "t4g.medium"
}

variable "ecs_min_instances" {
  description = "Minimum number of ECS instances"
  type        = number
  default     = 2
}

variable "ecs_max_instances" {
  description = "Maximum number of ECS instances"
  type        = number
  default     = 4
}

variable "ecs_desired_instances" {
  description = "Desired number of ECS instances"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# ECS Task Configuration
# -----------------------------------------------------------------------------

variable "wordpress_cpu" {
  description = "CPU units for WordPress container (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "wordpress_memory" {
  description = "Memory for WordPress container in MB"
  type        = number
  default     = 1024
}

variable "wordpress_desired_count" {
  description = "Number of WordPress containers to run"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# RDS Configuration
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class (must be Graviton for ARM64)"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the WordPress database"
  type        = string
  default     = "wordpress"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "wpadmin"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Graviton/ARM64 Instance Types:
#   - t4g.micro, t4g.small, t4g.medium, t4g.large (burstable)
#   - m6g.medium, m6g.large, m6g.xlarge (general purpose)
#   - c6g.medium, c6g.large, c6g.xlarge (compute optimized)
#   - r6g.medium, r6g.large, r6g.xlarge (memory optimized)
#
# RDS Graviton Instance Classes:
#   - db.t4g.micro, db.t4g.small, db.t4g.medium (burstable)
#   - db.m6g.large, db.m6g.xlarge (general purpose)
#   - db.r6g.large, db.r6g.xlarge (memory optimized)
#
# Cost Optimization Tips:
#   - Set single_nat_gateway = true to save ~$32/month
#   - Use db.t4g.micro for dev/test environments
#   - Set db_multi_az = false for non-production (saves ~50% on RDS)
# =============================================================================