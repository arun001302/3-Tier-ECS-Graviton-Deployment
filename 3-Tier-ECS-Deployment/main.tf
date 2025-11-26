# =============================================================================
# Main Terraform Configuration
# =============================================================================
# Root module that orchestrates all child modules
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------
# Creates: VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
# -----------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Groups Module
# -----------------------------------------------------------------------------
# Creates: ALB, ECS, and RDS security groups with proper ingress/egress rules
# -----------------------------------------------------------------------------

module "security_groups" {
  source = "./modules/security-groups"

  name_prefix    = local.name_prefix
  vpc_id         = module.vpc.vpc_id
  vpc_cidr       = var.vpc_cidr
  container_port = local.container_port
  db_port        = local.db_port

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# IAM Module
# -----------------------------------------------------------------------------
# Creates: ECS Task Role, Execution Role, EC2 Instance Profile
# -----------------------------------------------------------------------------

module "iam" {
  source = "./modules/iam"

  name_prefix    = local.name_prefix
  aws_region     = var.aws_region
  account_id     = local.account_id
  ecr_repository_arn = module.ecr.repository_arn
  log_group_name = local.ecs_log_group

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECR Module
# -----------------------------------------------------------------------------
# Creates: ECR Repository for WordPress container image
# -----------------------------------------------------------------------------

module "ecr" {
  source = "./modules/ecr"

  repository_name = local.ecr_repository_name

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ACM Module
# -----------------------------------------------------------------------------
# Creates: SSL/TLS Certificate with DNS validation
# -----------------------------------------------------------------------------

module "acm" {
  source = "./modules/acm"

  domain_name     = local.fqdn
  zone_id         = local.route53_zone_id
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ALB Module
# -----------------------------------------------------------------------------
# Creates: Application Load Balancer, Target Group, HTTP/HTTPS Listeners
# -----------------------------------------------------------------------------

module "alb" {
  source = "./modules/alb"

  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_id  = module.security_groups.alb_security_group_id
  certificate_arn    = module.acm.certificate_arn
  container_port     = local.container_port
  health_check_path  = "/"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# RDS Module
# -----------------------------------------------------------------------------
# Creates: RDS MySQL instance, Subnet Group, Parameter Group
# -----------------------------------------------------------------------------

module "rds" {
  source = "./modules/rds"

  name_prefix              = local.name_prefix
  identifier               = local.db_identifier
  instance_class           = var.db_instance_class
  allocated_storage        = var.db_allocated_storage
  db_name                  = var.db_name
  username                 = var.db_username
  multi_az                 = var.db_multi_az
  backup_retention_period  = var.db_backup_retention_period
  private_subnet_ids       = module.vpc.private_subnet_ids
  security_group_id        = module.security_groups.rds_security_group_id
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECS Cluster Module
# -----------------------------------------------------------------------------
# Creates: ECS Cluster, Launch Template, ASG, Capacity Provider
# -----------------------------------------------------------------------------

module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  name_prefix           = local.name_prefix
  cluster_name          = local.ecs_cluster_name
  instance_type         = var.ecs_instance_type
  ami_id                = local.ecs_ami_id
  min_instances         = var.ecs_min_instances
  max_instances         = var.ecs_max_instances
  desired_instances     = var.ecs_desired_instances
  private_subnet_ids    = module.vpc.private_subnet_ids
  security_group_id     = module.security_groups.ecs_security_group_id
  instance_profile_name = module.iam.instance_profile_name

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECS Service Module
# -----------------------------------------------------------------------------
# Creates: Task Definition, ECS Service, CloudWatch Log Group
# -----------------------------------------------------------------------------

module "ecs_service" {
  source = "./modules/ecs-service"

  name_prefix        = local.name_prefix
  cluster_id         = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  capacity_provider  = module.ecs_cluster.capacity_provider_name
  
  # Task Definition
  task_role_arn      = module.iam.task_role_arn
  execution_role_arn = module.iam.execution_role_arn
  container_name     = local.container_name
  container_image    = "${module.ecr.repository_url}:latest"
  container_port     = local.container_port
  cpu                = var.wordpress_cpu
  memory             = var.wordpress_memory
  
  # WordPress Environment Variables
  wordpress_db_host  = module.rds.endpoint
  wordpress_db_name  = var.db_name
  wordpress_db_user  = var.db_username
  db_secret_arn      = module.rds.secret_arn
  
  # Service Configuration
  desired_count      = var.wordpress_desired_count
  target_group_arn   = module.alb.target_group_arn
  
  # Logging
  aws_region         = var.aws_region
  log_group_name     = local.ecs_log_group
  log_retention_days = var.log_retention_days

  tags = local.common_tags

  depends_on = [
    module.alb,
    module.rds,
    module.ecs_cluster
  ]
}

# -----------------------------------------------------------------------------
# Route53 Module
# -----------------------------------------------------------------------------
# Creates: DNS A Record pointing to ALB
# -----------------------------------------------------------------------------

module "route53" {
  source = "./modules/route53"

  zone_id        = local.route53_zone_id
  record_name    = local.fqdn
  alb_dns_name   = module.alb.alb_dns_name
  alb_zone_id    = module.alb.alb_zone_id
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Module Dependency Order (Terraform handles this automatically):
#   1. vpc           - Network foundation
#   2. security_groups - Depends on VPC
#   3. iam           - No dependencies
#   4. ecr           - No dependencies
#   5. acm           - Depends on Route53 zone (data source)
#   6. rds           - Depends on VPC, security_groups
#   7. alb           - Depends on VPC, security_groups, ACM
#   8. ecs_cluster   - Depends on VPC, security_groups, IAM
#   9. ecs_service   - Depends on everything above
#   10. route53      - Depends on ALB
#
# Explicit depends_on is used for ecs_service to ensure:
#   - ALB target group exists before service registration
#   - RDS is ready before WordPress tries to connect
#   - ECS cluster capacity provider is configured
#
# ============================================================================= 