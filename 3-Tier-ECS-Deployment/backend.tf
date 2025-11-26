# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Stores Terraform state remotely in S3 with DynamoDB locking
# This enables team collaboration and prevents state corruption
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "3-tier-graviton-deployment-arun"
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    
    # Optional: DynamoDB table for state locking
    # Uncomment if you create a DynamoDB table named "terraform-state-lock"
    # dynamodb_table = "terraform-state-lock"
  }
}

# =============================================================================
# NOTES:
# =============================================================================
# 
# Before running `terraform init`, ensure:
#   1. The S3 bucket exists (✓ already have: 3-tier-graviton-deployment-arun)
#   2. You have AWS credentials configured with S3 access
#   3. (Optional) Create DynamoDB table for state locking:
#
#      aws dynamodb create-table \
#        --table-name terraform-state-lock \
#        --attribute-definitions AttributeName=LockID,AttributeType=S \
#        --key-schema AttributeName=LockID,KeyType=HASH \
#        --billing-mode PAY_PER_REQUEST \
#        --region us-east-1
#
# State file location: s3://3-tier-graviton-deployment-arun/terraform/state/terraform.tfstate
# =============================================================================