# Phase 3: Terraform Automation

This phase provides the complete infrastructure as code using Terraform. All resources created manually in Phase 1 are fully automated, enabling consistent, repeatable deployments across environments.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [Project Structure](#-project-structure)
- [Module Reference](#-module-reference)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Post-Deployment](#-post-deployment)
- [Managing the Infrastructure](#-managing-the-infrastructure)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Overview

The Terraform configuration in this repository automates the entire 3-tier architecture:

| Metric | Value |
|--------|-------|
| **Total Resources** | ~65 AWS resources |
| **Modules** | 10 reusable modules |
| **Deployment Time** | ~15 minutes |
| **State Management** | S3 backend with versioning |

### Why Terraform?

Enterprises choose Terraform for infrastructure automation because it provides:

- **Repeatability:** Deploy identical environments for dev, staging, and production
- **Version Control:** Track infrastructure changes alongside application code
- **Drift Detection:** Identify when infrastructure deviates from desired state
- **Collaboration:** Enable team workflows with remote state and locking
- **Documentation:** Code serves as living documentation of the infrastructure

---

## ✅ Prerequisites

Before deploying, ensure you have:

1. **AWS CLI** installed and configured with appropriate credentials
2. **Terraform** version 1.5.0 or higher
3. **Docker** installed for pushing images to ECR
4. **S3 Bucket** for Terraform state (create this manually beforehand)
5. **Route 53 Hosted Zone** for your domain

### Create the State Bucket

Before running Terraform, create an S3 bucket for state storage:

```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```

---

## 📁 Project Structure

```
3-tier-ecs-deployment/
│
├── backend.tf                 # S3 backend configuration for state
├── providers.tf               # AWS provider and version constraints
├── variables.tf               # Input variables with defaults
├── locals.tf                  # Naming conventions and computed values
├── data.tf                    # Data sources (AMI, Route53 zone, etc.)
├── main.tf                    # Root module orchestrating all child modules
├── outputs.tf                 # Output values (URLs, ARNs, etc.)
├── terraform.tfvars.example   # Example variable values
│
├── modules/
│   ├── vpc/                   # Network infrastructure
│   ├── security-groups/       # Firewall rules
│   ├── iam/                   # Roles and policies
│   ├── ecr/                   # Container registry
│   ├── acm/                   # SSL certificate
│   ├── alb/                   # Load balancer
│   ├── rds/                   # Database
│   ├── ecs-cluster/           # ECS cluster and EC2 instances
│   ├── ecs-service/           # Task definition and service
│   └── route53/               # DNS records
│
└── scripts/
    └── push-to-ecr.sh         # Helper script for ECR image push
```

---

## 📦 Module Reference

Each module encapsulates a specific component of the architecture. This modular design enables reuse and maintainability.

### VPC Module (`modules/vpc/`)

Creates the network foundation for the architecture.

| Resource | Description |
|----------|-------------|
| VPC | Main VPC with DNS support enabled |
| Public Subnets | 2 subnets for ALB and NAT Gateway |
| Private Subnets | 2 subnets for ECS and RDS |
| Internet Gateway | Enables public internet access |
| NAT Gateway | Enables private subnet outbound access |
| Route Tables | Routing for public and private subnets |

---

### Security Groups Module (`modules/security-groups/`)

Implements network-level access control following least-privilege principles.

| Security Group | Inbound Rules | Outbound Rules |
|----------------|---------------|----------------|
| ALB | HTTP/HTTPS from internet | Ephemeral ports to ECS |
| ECS | Ephemeral ports from ALB | All (for image pulls, RDS) |
| RDS | MySQL 3306 from ECS only | None required |

**Important:** The ALB security group includes outbound rules for ephemeral ports (32768-65535), which is required for dynamic port mapping with ECS bridge networking.

---

### IAM Module (`modules/iam/`)

Creates roles and policies for secure service-to-service communication.

| Role | Purpose | Key Permissions |
|------|---------|-----------------|
| ECS Task Execution Role | Allows ECS to start tasks | ECR pull, CloudWatch Logs, Secrets Manager |
| ECS Task Role | Permissions for running containers | SSM for exec access |
| ECS Instance Role | Allows EC2 to join ECS cluster | ECS registration, SSM, CloudWatch |

---

### ECR Module (`modules/ecr/`)

Creates a private container registry with lifecycle policies.

| Feature | Configuration |
|---------|---------------|
| Image Scanning | Enabled on push |
| Encryption | AES-256 |
| Lifecycle Policy | Keeps last 10 tagged images, deletes untagged after 7 days |

---

### ACM Module (`modules/acm/`)

Provisions and validates an SSL certificate.

| Feature | Configuration |
|---------|---------------|
| Validation Method | DNS (automatic with Route 53) |
| Key Algorithm | RSA-2048 |
| Auto-Renewal | Yes (managed by AWS) |

---

### ALB Module (`modules/alb/`)

Creates an internet-facing Application Load Balancer.

| Component | Configuration |
|-----------|---------------|
| Scheme | Internet-facing |
| Listeners | HTTP (redirect to HTTPS), HTTPS |
| Target Group | Instance-based, health checks on `/` |
| SSL Policy | ELBSecurityPolicy-TLS13-1-2-2021-06 |

---

### RDS Module (`modules/rds/`)

Deploys a managed MySQL database with high availability.

| Feature | Configuration |
|---------|---------------|
| Engine | MySQL 8.0 |
| Instance Class | db.t4g.micro (Graviton) |
| Multi-AZ | Enabled |
| Storage | 20GB gp3 with auto-scaling |
| Credentials | Stored in Secrets Manager |
| Encryption | Enabled |

---

### ECS Cluster Module (`modules/ecs-cluster/`)

Creates the ECS cluster with Graviton EC2 instances.

| Feature | Configuration |
|---------|---------------|
| Capacity Provider | EC2 with managed scaling |
| Instance Type | t4g.medium (ARM64) |
| Auto Scaling | Min 2, Max 4 instances |
| AMI | Amazon Linux 2023 (ARM64) |
| Container Insights | Enabled |

---

### ECS Service Module (`modules/ecs-service/`)

Deploys the WordPress containers as an ECS service.

| Feature | Configuration |
|---------|---------------|
| Task CPU | 512 units |
| Task Memory | 1024 MB |
| Desired Count | 2 tasks |
| Network Mode | Bridge with dynamic port mapping |
| Deployment | Rolling update with circuit breaker |
| Auto Scaling | Target tracking on CPU/memory |

---

### Route 53 Module (`modules/route53/`)

Creates DNS records pointing to the load balancer.

| Record | Type | Target |
|--------|------|--------|
| wp.yourdomain.com | A (Alias) | Application Load Balancer |

---

## ⚙️ Configuration

### Step 1: Update Backend Configuration

Edit `backend.tf` with your S3 bucket name:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "3-tier-graviton/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Step 2: Create Variables File

Copy the example file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# Project
project_name = "3-tier-graviton"
environment  = "dev"
aws_region   = "us-east-1"

# Domain
domain_name     = "yourdomain.com"
subdomain       = "wp"

# Database
db_name     = "wordpress"
db_username = "wpadmin"

# Cost Optimization
single_nat_gateway = true
```

### Key Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Prefix for all resource names | `3-tier-graviton` |
| `environment` | Environment name (dev, staging, prod) | `dev` |
| `aws_region` | AWS region for deployment | `us-east-1` |
| `domain_name` | Your Route 53 hosted zone domain | - |
| `subdomain` | Subdomain for WordPress | `wp` |
| `vpc_cidr` | CIDR block for VPC | `10.0.0.0/16` |
| `ecs_instance_type` | EC2 instance type for ECS | `t4g.medium` |
| `db_instance_class` | RDS instance class | `db.t4g.micro` |
| `single_nat_gateway` | Use one NAT Gateway (cost saving) | `true` |

---

## 🚀 Deployment

### Step 1: Initialize Terraform

```bash
terraform init
```

This downloads provider plugins and initializes the backend.

### Step 2: Review the Plan

```bash
terraform plan
```

Review the resources that will be created. You should see approximately 65 resources.

### Step 3: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. Deployment takes approximately 15 minutes.

**Note:** The longest operations are:
- ACM certificate validation (~3-5 minutes)
- RDS Multi-AZ creation (~8-10 minutes)

### Step 4: Push WordPress Image to ECR

After the ECR repository is created, push the WordPress ARM64 image:

```bash
# Make script executable
chmod +x scripts/push-to-ecr.sh

# Run the push script
./scripts/push-to-ecr.sh
```

Or manually:

```bash
# Get ECR repository URL from Terraform output
ECR_URL=$(terraform output -raw ecr_repository_url)

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_URL%/*}

# Pull, tag, and push
docker pull --platform linux/arm64 wordpress:latest
docker tag wordpress:latest ${ECR_URL}:latest
docker push ${ECR_URL}:latest
```

### Step 5: Force ECS Deployment

After pushing the image, trigger a new deployment:

```bash
aws ecs update-service \
  --cluster 3-tier-graviton-dev-cluster \
  --service 3-tier-graviton-dev-service \
  --force-new-deployment \
  --region us-east-1
```

---

## ✅ Post-Deployment

### View Outputs

```bash
terraform output
```

Key outputs include:
- `application_url` - Your WordPress URL
- `alb_dns_name` - Direct ALB DNS name
- `ecr_repository_url` - ECR repository for image pushes
- `rds_endpoint` - Database endpoint (for debugging)

### Verify Deployment

1. **Check ECS Service:**
```bash
aws ecs describe-services \
  --cluster 3-tier-graviton-dev-cluster \
  --services 3-tier-graviton-dev-service \
  --query "services[0].{desired:desiredCount,running:runningCount}" \
  --region us-east-1
```

2. **Check Target Health:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn) \
  --region us-east-1
```

3. **Access WordPress:**
Open `https://wp.yourdomain.com` in your browser.

---

## 🔧 Managing the Infrastructure

### Update Configuration

1. Modify variables in `terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Scale ECS Tasks

```bash
aws ecs update-service \
  --cluster 3-tier-graviton-dev-cluster \
  --service 3-tier-graviton-dev-service \
  --desired-count 4 \
  --region us-east-1
```

### View Logs

```bash
aws logs tail /ecs/3-tier-graviton-dev --since 1h --follow --region us-east-1
```

### Destroy Infrastructure

To tear down all resources:

```bash
terraform destroy
```

**Warning:** This will delete all resources including the database. Ensure you have backups if needed.

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Targets showing unhealthy**

Check that the ALB security group allows outbound traffic to ECS on ephemeral ports (32768-65535). This is the most common issue with ECS bridge networking and dynamic port mapping.

**Issue: Tasks not starting**

1. Check CloudWatch Logs for container errors
2. Verify the ECR image exists and is accessible
3. Ensure Secrets Manager secret is readable by the execution role

**Issue: Certificate validation pending**

Ensure Route 53 hosted zone is properly configured and the domain nameservers are correct. DNS validation can take up to 30 minutes.

**Issue: RDS connection refused**

1. Verify security group allows traffic from ECS security group
2. Check that RDS is in the correct VPC and subnets
3. Verify credentials in Secrets Manager match RDS

### Useful Commands

```bash
# Check ECS task status
aws ecs list-tasks --cluster 3-tier-graviton-dev-cluster --region us-east-1

# Describe a specific task
aws ecs describe-tasks --cluster 3-tier-graviton-dev-cluster --tasks <task-arn> --region us-east-1

# Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id> --region us-east-1

# View recent CloudWatch logs
aws logs get-log-events --log-group-name /ecs/3-tier-graviton-dev --log-stream-name <stream-name> --region us-east-1
```

---

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
- [AWS Graviton Getting Started](https://aws.amazon.com/ec2/graviton/)

---

## ⬅️ Previous Phases

- [Phase 1: Manual Build](Phase1-Manual-Build.md) - Build the architecture manually to understand each component
- [Phase 2: Enterprise-Grade Upgrade Plan](Phase2-Enterprise-Upgrade.md) - Production enhancements and best practices
