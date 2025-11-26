# =============================================================================
# Local Values
# =============================================================================
# Computed values, naming conventions, and common configurations
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Naming Convention
  # ---------------------------------------------------------------------------
  # Format: {project}-{environment}-{resource}
  # Example: 3-tier-graviton-dev-vpc
  # ---------------------------------------------------------------------------
  
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Full domain name for the application
  fqdn = "${var.subdomain}.${var.domain_name}"

  # ---------------------------------------------------------------------------
  # Common Tags
  # ---------------------------------------------------------------------------
  # These are merged with provider default_tags for resource-specific tagging
  # ---------------------------------------------------------------------------
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # ---------------------------------------------------------------------------
  # Networking
  # ---------------------------------------------------------------------------
  
  # Number of AZs to use
  az_count = length(var.availability_zones)
  
  # NAT Gateway count (1 for cost savings, or 1 per AZ for HA)
  nat_gateway_count = var.single_nat_gateway ? 1 : local.az_count

  # ---------------------------------------------------------------------------
  # ECS Configuration
  # ---------------------------------------------------------------------------
  
  # ECS cluster name
  ecs_cluster_name = "${local.name_prefix}-cluster"
  
  # ECS service name
  ecs_service_name = "${local.name_prefix}-wordpress"
  
  # Container name (used in task definition and ALB target group)
  container_name = "wordpress"
  
  # Container port
  container_port = 80

  # ---------------------------------------------------------------------------
  # RDS Configuration
  # ---------------------------------------------------------------------------
  
  # RDS identifier
  db_identifier = "mysql-${local.name_prefix}"
  
  # Database port
  db_port = 3306

  # ---------------------------------------------------------------------------
  # ECR Configuration
  # ---------------------------------------------------------------------------
  
  # ECR repository name
  ecr_repository_name = "${local.name_prefix}-wordpress"

  # ---------------------------------------------------------------------------
  # CloudWatch Log Groups
  # ---------------------------------------------------------------------------
  
  # Log group for ECS tasks
  ecs_log_group = "/ecs/${local.name_prefix}"

  # ---------------------------------------------------------------------------
  # Resource Names
  # ---------------------------------------------------------------------------
  
  resource_names = {
    vpc                = "${local.name_prefix}-vpc"
    igw                = "${local.name_prefix}-igw"
    nat                = "${local.name_prefix}-nat"
    alb                = "${local.name_prefix}-alb"
    target_group       = "${local.name_prefix}-tg"
    ecs_cluster        = "${local.name_prefix}-cluster"
    ecs_service        = "${local.name_prefix}-service"
    task_definition    = "${local.name_prefix}-task"
    ecr_repository     = "${local.name_prefix}-wordpress"
    rds                = "${local.name_prefix}-mysql"
    security_group_alb = "${local.name_prefix}-sg-alb"
    security_group_ecs = "${local.name_prefix}-sg-ecs"
    security_group_rds = "${local.name_prefix}-sg-rds"
    iam_task_role      = "${local.name_prefix}-task-role"
    iam_execution_role = "${local.name_prefix}-execution-role"
    iam_instance_role  = "${local.name_prefix}-instance-role"
    launch_template    = "${local.name_prefix}-lt"
    asg                = "${local.name_prefix}-asg"
    capacity_provider  = "${local.name_prefix}-cp"
  }
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Why use locals?
#   1. DRY (Don't Repeat Yourself) - define once, use everywhere
#   2. Computed values - combine variables into useful formats
#   3. Naming consistency - all resources follow the same pattern
#   4. Easy refactoring - change naming convention in one place
#
# Naming Convention Benefits:
#   - Easy to identify resources in AWS Console
#   - Clear project and environment association
#   - Predictable names for scripting and automation
#   - Helps with cost allocation and billing reports
#
# Usage in modules:
#   module "vpc" {
#     name = local.resource_names.vpc
#     ...
#   }
# =============================================================================