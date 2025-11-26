# =============================================================================
# Terraform Variables Example File
# =============================================================================
# Copy this file to terraform.tfvars and customize for your deployment
# 
# Usage:
#   cp terraform.tfvars.example terraform.tfvars
#   # Edit terraform.tfvars with your values
#   terraform plan
# =============================================================================

# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------

project_name = "3-tier-graviton"
environment  = "dev"
aws_region   = "us-east-1"

# -----------------------------------------------------------------------------
# Networking Configuration
# -----------------------------------------------------------------------------

vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# Set to true to use single NAT Gateway (saves ~$32/month)
# Set to false for high availability (one NAT per AZ)
single_nat_gateway = true

# -----------------------------------------------------------------------------
# Domain and SSL Configuration
# -----------------------------------------------------------------------------

# Your domain (must already exist in Route53)
domain_name = "architecture-demo.com"

# Subdomain for WordPress (creates: wp.architecture-demo.com)
subdomain = "wp"

# -----------------------------------------------------------------------------
# ECS EC2 Configuration
# -----------------------------------------------------------------------------

# Graviton instance type (ARM64)
# Options: t4g.micro, t4g.small, t4g.medium, t4g.large
ecs_instance_type = "t4g.medium"

# Auto Scaling Group settings
ecs_min_instances     = 2
ecs_max_instances     = 4
ecs_desired_instances = 2

# -----------------------------------------------------------------------------
# WordPress Container Configuration
# -----------------------------------------------------------------------------

# CPU units (1024 = 1 vCPU)
wordpress_cpu = 512

# Memory in MB
wordpress_memory = 1024

# Number of WordPress containers (tasks)
wordpress_desired_count = 2

# -----------------------------------------------------------------------------
# RDS MySQL Configuration
# -----------------------------------------------------------------------------

# Graviton instance class (ARM64)
# Options: db.t4g.micro, db.t4g.small, db.t4g.medium
db_instance_class = "db.t4g.micro"

# Storage in GB
db_allocated_storage = 20

# Database name
db_name = "wordpress"

# Master username (password generated automatically)
db_username = "admin"

# Multi-AZ for high availability (doubles cost)
db_multi_az = true

# Backup retention (days)
db_backup_retention_period = 7

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------

# CloudWatch log retention (days)
# Options: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
log_retention_days = 30

# =============================================================================
# COST ESTIMATION (us-east-1)
# =============================================================================
#
# With these settings (approximate monthly cost):
#
#   EC2 (2x t4g.medium)         ~$27
#   RDS (db.t4g.micro Multi-AZ) ~$25
#   NAT Gateway (1x)            ~$32
#   ALB                         ~$16
#   ECR (minimal storage)       ~$1
#   Route53                     ~$1
#   CloudWatch Logs             ~$1
#   ----------------------------------------
#   TOTAL                       ~$103/month
#
# Cost Optimization Tips:
#   - single_nat_gateway = true saves ~$32/month
#   - db_multi_az = false saves ~$12/month (not recommended for prod)
#   - ecs_instance_type = "t4g.small" saves ~$13/month
#   - Minimum config possible: ~$60/month
#
# =============================================================================

# =============================================================================
# IMPORTANT: DO NOT COMMIT terraform.tfvars TO GIT
# =============================================================================
# Add to .gitignore:
#   terraform.tfvars
#   *.tfvars
#   !terraform.tfvars.example
# =============================================================================