# =============================================================================
# ECR Module
# =============================================================================
# Creates ECR repository for WordPress container images
# =============================================================================

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# ECR Lifecycle Policy
# -----------------------------------------------------------------------------
# Automatically clean up old images to save storage costs
# -----------------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 'latest' images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 4
        description  = "Keep only last 20 images total"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Image Tag Mutability:
#   - MUTABLE: Same tag can be overwritten (e.g., "latest")
#   - IMMUTABLE: Tags are permanent, safer for production
#   - Using MUTABLE for simplicity in this project
#
# Image Scanning:
#   - Automatically scans images for vulnerabilities on push
#   - Results visible in AWS Console or via API
#   - No additional cost for basic scanning
#
# Lifecycle Policy:
#   - Prevents unbounded storage growth
#   - Keeps recent images, removes old ones
#   - Saves costs on ECR storage
#
# Encryption:
#   - AES256: AWS managed encryption (free)
#   - KMS: Customer managed keys (additional cost)
#
# Push Commands (after terraform apply):
#   aws ecr get-login-password --region us-east-1 | \
#     docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
#   
#   docker pull --platform linux/arm64 wordpress:latest
#   docker tag wordpress:latest <repo-url>:latest
#   docker push <repo-url>:latest
#
# =============================================================================