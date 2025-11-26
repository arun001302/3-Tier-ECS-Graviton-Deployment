# =============================================================================
# Root Module Outputs
# =============================================================================
# Important values displayed after terraform apply
# =============================================================================

# -----------------------------------------------------------------------------
# Application Access
# -----------------------------------------------------------------------------

output "application_url" {
  description = "URL to access the WordPress application"
  value       = "https://${local.fqdn}"
}

output "alb_dns_name" {
  description = "ALB DNS name (use if DNS not propagated yet)"
  value       = module.alb.alb_dns_name
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# -----------------------------------------------------------------------------
# ECS
# -----------------------------------------------------------------------------

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.service_name
}

# -----------------------------------------------------------------------------
# ECR
# -----------------------------------------------------------------------------

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_push_commands" {
  description = "Commands to push Docker image to ECR"
  value       = <<-EOT
    
    # Authenticate Docker to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
    
    # Pull WordPress ARM64 image
    docker pull --platform linux/arm64 wordpress:latest
    
    # Tag for ECR
    docker tag wordpress:latest ${module.ecr.repository_url}:latest
    
    # Push to ECR
    docker push ${module.ecr.repository_url}:latest
    
  EOT
}

# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = var.db_name
}

# -----------------------------------------------------------------------------
# Route53 / DNS
# -----------------------------------------------------------------------------

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.route53_zone_id
}

output "domain_name" {
  description = "Full domain name for the application"
  value       = local.fqdn
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.task_role_arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = module.iam.execution_role_arn
}

# -----------------------------------------------------------------------------
# CloudWatch
# -----------------------------------------------------------------------------

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS tasks"
  value       = local.ecs_log_group
}

# -----------------------------------------------------------------------------
# Useful Commands
# -----------------------------------------------------------------------------

output "useful_commands" {
  description = "Helpful AWS CLI commands for managing the deployment"
  value       = <<-EOT
    
    # View ECS service status
    aws ecs describe-services --cluster ${local.ecs_cluster_name} --services ${local.ecs_service_name} --region ${var.aws_region}
    
    # View running tasks
    aws ecs list-tasks --cluster ${local.ecs_cluster_name} --service-name ${local.ecs_service_name} --region ${var.aws_region}
    
    # View ECS container logs
    aws logs tail ${local.ecs_log_group} --follow --region ${var.aws_region}
    
    # Force new deployment (after pushing new image)
    aws ecs update-service --cluster ${local.ecs_cluster_name} --service ${local.ecs_service_name} --force-new-deployment --region ${var.aws_region}
    
    # SSH to ECS instance (if needed)
    aws ssm start-session --target <instance-id> --region ${var.aws_region}
    
  EOT
}

# =============================================================================
# NOTES:
# =============================================================================
#
# After terraform apply, you'll see these outputs. Key ones:
#
#   application_url  - Visit this to see WordPress
#   ecr_push_commands - Run these to push the Docker image
#   useful_commands   - Helpful CLI commands for management
#
# To see outputs again after deployment:
#   terraform output
#
# To get a specific output:
#   terraform output application_url
#
# To get output as JSON (for scripting):
#   terraform output -json
# =============================================================================