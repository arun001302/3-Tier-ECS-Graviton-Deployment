# =============================================================================
# Data Sources
# =============================================================================
# Fetches existing AWS resources and dynamic information
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Account and Region Information
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Availability Zones
# -----------------------------------------------------------------------------
# Get available AZs in the region (filters out Local Zones)
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# -----------------------------------------------------------------------------
# ECS Optimized AMI for ARM64 (Graviton)
# -----------------------------------------------------------------------------
# Amazon Linux 2023 ECS-optimized AMI for ARM64 architecture
# -----------------------------------------------------------------------------

data "aws_ssm_parameter" "ecs_ami_arm64" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}

# -----------------------------------------------------------------------------
# Route53 Hosted Zone
# -----------------------------------------------------------------------------
# Lookup existing hosted zone for the domain
# -----------------------------------------------------------------------------

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# -----------------------------------------------------------------------------
# Local Values from Data Sources
# -----------------------------------------------------------------------------

locals {
  # AWS Account ID
  account_id = data.aws_caller_identity.current.account_id
  
  # Current region
  region = data.aws_region.current.name
  
  # ECS optimized AMI ID for ARM64
  ecs_ami_id = data.aws_ssm_parameter.ecs_ami_arm64.value
  
  # Route53 Zone ID
  route53_zone_id = data.aws_route53_zone.main.zone_id
  
  # ECR repository URL (constructed)
  ecr_repository_url = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.ecr_repository_name}"
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Why use data sources?
#   1. Dynamic values - AMI IDs change frequently, SSM parameter always has latest
#   2. Avoid hardcoding - Account IDs, region, zone IDs fetched automatically
#   3. Existing resources - Reference resources created outside Terraform
#
# ECS Optimized AMI:
#   - Using SSM Parameter ensures we always get the latest AMI
#   - ARM64 AMI is specifically for Graviton instances
#   - Amazon Linux 2023 is the latest recommended OS for ECS
#
# Alternative AMI lookup (if SSM doesn't work):
#
#   data "aws_ami" "ecs_arm64" {
#     most_recent = true
#     owners      = ["amazon"]
#
#     filter {
#       name   = "name"
#       values = ["al2023-ami-ecs-hvm-*-arm64"]
#     }
#
#     filter {
#       name   = "virtualization-type"
#       values = ["hvm"]
#     }
#   }
#
# Route53 Zone:
#   - Must exist before running Terraform
#   - Domain: architecture-demo.com
#   - Verify with: aws route53 list-hosted-zones
# =============================================================================