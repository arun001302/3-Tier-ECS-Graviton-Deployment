# =============================================================================
# Terraform and Provider Configuration
# =============================================================================
# Defines required Terraform version and AWS provider settings
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# AWS Provider Configuration
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "https://github.com/yourusername/3-tier-graviton-deployment"
    }
  }
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Provider version ~> 5.0 means:
#   - Minimum version: 5.0.0
#   - Maximum version: < 6.0.0 (any 5.x version)
#
# Default tags are automatically applied to ALL resources created by this
# provider, ensuring consistent tagging across the infrastructure.
#
# Authentication methods (in order of precedence):
#   1. Environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
#   2. Shared credentials file: ~/.aws/credentials
#   3. IAM instance profile (if running on EC2)
#   4. IAM role (if running in ECS/Lambda)
#
# To use a specific profile:
#   provider "aws" {
#     region  = var.aws_region
#     profile = "your-profile-name"
#   }
# =============================================================================