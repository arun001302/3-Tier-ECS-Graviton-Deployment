#!/bin/bash
# =============================================================================
# Push WordPress ARM64 Image to ECR
# =============================================================================
# This script pulls the official WordPress ARM64 image and pushes it to ECR
# 
# Usage:
#   ./scripts/push-to-ecr.sh
#
# Prerequisites:
#   - AWS CLI configured with appropriate credentials
#   - Docker installed and running
#   - Terraform has been applied (ECR repository exists)
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

AWS_REGION="${AWS_REGION:-us-east-1}"
WORDPRESS_VERSION="${WORDPRESS_VERSION:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# -----------------------------------------------------------------------------
# Pre-flight Checks
# -----------------------------------------------------------------------------

log_info "Running pre-flight checks..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it and try again."
    exit 1
fi

# Check if Terraform outputs are available
if ! command -v terraform &> /dev/null; then
    log_error "Terraform is not installed. Please install it and try again."
    exit 1
fi

# -----------------------------------------------------------------------------
# Get ECR Repository URL from Terraform
# -----------------------------------------------------------------------------

log_info "Getting ECR repository URL from Terraform outputs..."

cd "$(dirname "$0")/.."

ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url 2>/dev/null) || {
    log_error "Failed to get ECR repository URL. Have you run 'terraform apply'?"
    exit 1
}

AWS_ACCOUNT_ID=$(echo "$ECR_REPOSITORY_URL" | cut -d'.' -f1)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

log_info "ECR Repository: ${ECR_REPOSITORY_URL}"

# -----------------------------------------------------------------------------
# Authenticate Docker to ECR
# -----------------------------------------------------------------------------

log_info "Authenticating Docker to ECR..."

aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${ECR_REGISTRY}"

if [ $? -ne 0 ]; then
    log_error "Failed to authenticate with ECR"
    exit 1
fi

log_info "Successfully authenticated with ECR"

# -----------------------------------------------------------------------------
# Pull WordPress ARM64 Image
# -----------------------------------------------------------------------------

log_info "Pulling WordPress ARM64 image (version: ${WORDPRESS_VERSION})..."

docker pull --platform linux/arm64 "wordpress:${WORDPRESS_VERSION}"

if [ $? -ne 0 ]; then
    log_error "Failed to pull WordPress image"
    exit 1
fi

log_info "Successfully pulled WordPress image"

# -----------------------------------------------------------------------------
# Tag Image for ECR
# -----------------------------------------------------------------------------

log_info "Tagging image for ECR..."

# Tag as latest
docker tag "wordpress:${WORDPRESS_VERSION}" "${ECR_REPOSITORY_URL}:latest"

# Tag with version
docker tag "wordpress:${WORDPRESS_VERSION}" "${ECR_REPOSITORY_URL}:${WORDPRESS_VERSION}"

# Tag with timestamp for rollback capability
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker tag "wordpress:${WORDPRESS_VERSION}" "${ECR_REPOSITORY_URL}:${TIMESTAMP}"

log_info "Tagged image with: latest, ${WORDPRESS_VERSION}, ${TIMESTAMP}"

# -----------------------------------------------------------------------------
# Push Image to ECR
# -----------------------------------------------------------------------------

log_info "Pushing image to ECR..."

docker push "${ECR_REPOSITORY_URL}:latest"
docker push "${ECR_REPOSITORY_URL}:${WORDPRESS_VERSION}"
docker push "${ECR_REPOSITORY_URL}:${TIMESTAMP}"

if [ $? -ne 0 ]; then
    log_error "Failed to push image to ECR"
    exit 1
fi

log_info "Successfully pushed image to ECR"

# -----------------------------------------------------------------------------
# Verify Image in ECR
# -----------------------------------------------------------------------------

log_info "Verifying image in ECR..."

aws ecr describe-images \
    --repository-name "$(basename ${ECR_REPOSITORY_URL})" \
    --region "${AWS_REGION}" \
    --query 'imageDetails[*].{Tags:imageTags,Pushed:imagePushedAt,Size:imageSizeInBytes}' \
    --output table

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo ""
echo "============================================================================="
echo -e "${GREEN}SUCCESS!${NC} WordPress ARM64 image pushed to ECR"
echo "============================================================================="
echo ""
echo "Image URLs:"
echo "  - ${ECR_REPOSITORY_URL}:latest"
echo "  - ${ECR_REPOSITORY_URL}:${WORDPRESS_VERSION}"
echo "  - ${ECR_REPOSITORY_URL}:${TIMESTAMP}"
echo ""
echo "Next steps:"
echo "  1. If this is a new deployment, run: terraform apply"
echo "  2. To force ECS to use new image, run:"
echo "     aws ecs update-service --cluster <cluster-name> --service <service-name> --force-new-deployment"
echo ""
echo "============================================================================="