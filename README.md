# 3-Tier WordPress Deployment on AWS ECS with Graviton (ARM64)

[![AWS](https://img.shields.io/badge/AWS-ECS-orange?logo=amazon-aws)](https://aws.amazon.com/ecs/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple?logo=terraform)](https://www.terraform.io/)
[![Architecture](https://img.shields.io/badge/Architecture-ARM64-blue)](https://aws.amazon.com/ec2/graviton/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

A production-ready, enterprise-style 3-tier WordPress deployment on Amazon ECS using AWS Graviton (ARM64) instances. This project mirrors the architecture patterns used by large organizations to deploy containerized applications at scale, demonstrating infrastructure-as-code best practices, security-first design, and cost-optimized compute.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Technology Stack](#-technology-stack)
- [Project Phases](#-project-phases)
- [Cost Breakdown](#-cost-breakdown)
- [Key Features](#-key-features)
- [Lessons Learned](#-lessons-learned)
- [Getting Started](#-getting-started)
- [Repository Structure](#-repository-structure)
- [Author](#-author)

---

## 🎯 Project Overview

Large enterprises deploy applications using a 3-tier architecture to separate concerns, improve security, and enable independent scaling of each layer. This project implements that same pattern using modern AWS services:

| Tier | Component | Purpose |
|------|-----------|---------|
| **Web Tier** | Application Load Balancer | Distributes traffic, SSL termination, health checks |
| **Application Tier** | ECS on EC2 (Graviton) | Runs WordPress containers with auto-scaling |
| **Data Tier** | RDS MySQL (Multi-AZ) | Managed database with automatic failover |

### Enterprise Alignment

This architecture reflects how companies like Samsung, Expedia, and Capital One deploy containerized workloads on AWS. Key enterprise patterns implemented include:

- **Network Isolation:** Application and database tiers run in private subnets with no direct internet access, following the principle of least exposure
- **High Availability:** Resources deployed across multiple Availability Zones to meet typical enterprise SLAs of 99.9%+ uptime
- **Secrets Management:** Database credentials stored in AWS Secrets Manager, never hardcoded or stored in environment variables
- **Infrastructure as Code:** 100% Terraform automation enabling consistent, auditable, and repeatable deployments across environments
- **Cost Optimization:** AWS Graviton processors deliver up to 40% better price-performance, a strategy adopted by enterprises to reduce cloud spend

---

## 🏗️ Architecture

This deployment follows the AWS Well-Architected Framework and implements a classic enterprise 3-tier architecture.

### Architecture Components

| Layer | Components | Enterprise Benefit |
|-------|------------|-------------------|
| **Edge** | Route 53, ACM Certificate | Global DNS with health checks, free SSL with auto-renewal |
| **Web Tier** | Application Load Balancer in public subnets | Layer 7 routing, SSL termination, WAF-ready |
| **Application Tier** | ECS Cluster with Graviton EC2 in private subnets | Container orchestration, auto-scaling, no public exposure |
| **Data Tier** | RDS MySQL Multi-AZ in private subnets | Managed database, automatic failover, encrypted storage |
| **Supporting Services** | ECR, Secrets Manager, CloudWatch | Container registry, secrets management, observability |

### Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Compute** | ECS on EC2 (not Fargate) | More control over instance types, better cost predictability for sustained workloads |
| **Instance Type** | t4g.medium (Graviton) | 40% better price-performance than x86, widely adopted by enterprises |
| **Database** | RDS MySQL Multi-AZ | Managed service with automatic failover, reduces operational overhead |
| **NAT Gateway** | Single NAT Gateway | Cost optimization for non-production (~$32/month savings), enterprises typically use one per AZ in production |
| **Network Mode** | Bridge with Dynamic Port Mapping | Allows multiple containers per instance, maximizes resource utilization |
| **Secrets** | AWS Secrets Manager | Secure credential storage, automatic rotation capable, audit trail |

---

## 🛠️ Technology Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| **Container Orchestration** | Amazon ECS | Manages container lifecycle and placement |
| **Compute** | EC2 Graviton (t4g.medium) | ARM64-based instances for cost efficiency |
| **Database** | Amazon RDS MySQL 8.0 | Managed relational database |
| **Load Balancing** | Application Load Balancer | Layer 7 load balancing with SSL termination |
| **Container Registry** | Amazon ECR | Private Docker image storage |
| **DNS** | Amazon Route 53 | Domain management and routing |
| **SSL/TLS** | AWS Certificate Manager | Free SSL certificates with auto-renewal |
| **Secrets** | AWS Secrets Manager | Secure credential storage |
| **Monitoring** | Amazon CloudWatch | Logs, metrics, and alarms |
| **Infrastructure as Code** | Terraform | Automated, repeatable deployments |

---

## 📚 Project Phases

This project is structured in three phases, progressing from manual deployment to full automation:

### Phase 1: Manual Build

Build the entire infrastructure manually using the AWS Console. This phase teaches the fundamentals of how each AWS service works and how they connect together.

**What you'll learn:**
- Creating a VPC with public and private subnets
- Configuring security groups and IAM roles
- Setting up an ECS cluster with Graviton instances
- Deploying RDS MySQL with Multi-AZ
- Configuring an Application Load Balancer with SSL
- Understanding ECS task definitions and services

---

### Phase 2: Enterprise-Grade Upgrade Plan

A technical design document outlining production-ready enhancements and best practices.

**Topics covered:**
- High availability and disaster recovery
- Security hardening
- Monitoring and alerting strategies
- CI/CD pipeline integration
- Cost optimization techniques
- Performance tuning

---

### Phase 3: Terraform Automation

The complete infrastructure automated with Terraform. This phase provides production-ready, modular Terraform code that can be deployed with a single command.

**Features:**
- Modular Terraform design (10 modules)
- Remote state management with S3
- Parameterized for multiple environments
- Comprehensive outputs for integration

---

## 💰 Cost Breakdown

Estimated monthly costs for this deployment in **us-east-1**:

| Resource | Configuration | Monthly Cost |
|----------|---------------|--------------|
| EC2 (ECS Instances) | 2x t4g.medium | ~$27 |
| RDS MySQL | db.t4g.micro Multi-AZ | ~$25 |
| NAT Gateway | 1x (single AZ) | ~$32 |
| Application Load Balancer | 1x | ~$16 |
| ECR | <1GB storage | ~$0.10 |
| Route 53 | Hosted zone + queries | ~$0.50 |
| CloudWatch Logs | Basic logging | ~$2 |
| Secrets Manager | 1 secret | ~$0.40 |
| **Total** | | **~$103/month** |

### Cost Optimization Tips

| Optimization | Savings | Trade-off |
|--------------|---------|-----------|
| Single NAT Gateway (implemented) | ~$32/month | Reduced availability if AZ fails |
| Use db.t4g.micro (implemented) | ~$20/month vs db.t4g.small | Limited to 100 connections |
| Disable Multi-AZ for RDS | ~$12/month | No automatic failover |
| Use Spot Instances for ECS | ~$15/month | Possible interruptions |
| Reserved Instances (1-year) | ~30% overall | Upfront commitment |

---

## ✨ Key Features

### High Availability
- Multi-AZ deployment across us-east-1a and us-east-1b
- RDS automatic failover with synchronous replication
- ECS tasks spread across availability zones
- ALB health checks with automatic target replacement

### Security
- Private subnets for application and database tiers
- Security groups with least-privilege access
- Database credentials stored in Secrets Manager
- Encrypted storage (RDS and EBS)
- SSL/TLS encryption for traffic in transit
- IMDSv2 required on EC2 instances

### Scalability
- ECS Service Auto Scaling based on CPU/memory
- EC2 Auto Scaling Group (2-4 instances)
- ALB distributes traffic across healthy targets
- RDS storage auto-scaling enabled

### Monitoring
- CloudWatch Container Insights for ECS metrics
- Application logs streamed to CloudWatch Logs
- RDS Performance Insights available
- ALB access logs capability

---

## 📝 Lessons Learned

### Issue: ALB Health Checks Failing

**Symptom:** Target groups showed "unhealthy" despite containers running successfully.

**Root Cause:** When using ECS Bridge Mode with Dynamic Port Mapping, containers receive random high-numbered ports (32768-65535). The ALB security group only allowed outbound traffic on port 80, blocking health check traffic to the dynamic ports.

**Solution:** Updated the ALB security group to allow outbound traffic to the ephemeral port range (32768-65535) on the ECS security group.

**Key Takeaway:** With dynamic port mapping, ensure both:
- ECS security group allows **inbound** from ALB on ports 32768-65535
- ALB security group allows **outbound** to ECS on ports 32768-65535

---

## 🚀 Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Docker installed (for pushing images to ECR)
- Terraform >= 1.5.0 (for Phase 3)
- A domain hosted in Route 53

### Quick Start Options

**Option 1: Learn by Building Manually**
Follow Phase 1: Manual Build to understand each component.

**Option 2: Deploy with Terraform**
```bash
# Clone the repository
git clone https://github.com/arun001302/3-tier-graviton-deployment.git
cd 3-tier-graviton-deployment

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply

# Push WordPress image to ECR (after ECR is created)
./scripts/push-to-ecr.sh
```

---

## 📁 Repository Structure

```
3-tier-graviton-deployment/
│
├── README.md                      # This file - Project overview
├── Phase1-Manual-Build.md         # Manual deployment guide
├── Phase2-Enterprise-Upgrade.md   # Enterprise enhancement plan
├── Phase3-Terraform-Automation.md # Terraform guide
│
├── backend.tf                     # S3 backend configuration
├── providers.tf                   # AWS provider setup
├── variables.tf                   # Input variables
├── outputs.tf                     # Output values
├── locals.tf                      # Local values and naming
├── data.tf                        # Data sources
├── main.tf                        # Root module
├── terraform.tfvars.example       # Example variables
│
├── modules/
│   ├── vpc/                       # Network infrastructure
│   ├── security-groups/           # Security group rules
│   ├── iam/                       # IAM roles and policies
│   ├── ecr/                       # Container registry
│   ├── acm/                       # SSL certificate
│   ├── alb/                       # Load balancer
│   ├── rds/                       # Database
│   ├── ecs-cluster/               # ECS cluster and EC2
│   ├── ecs-service/               # ECS service and tasks
│   └── route53/                   # DNS records
│
├── scripts/
│   └── push-to-ecr.sh             # ECR push script
│
└── docs/
    └── architecture-diagram.png   # Architecture visual
```
---

## 🙏 Acknowledgments

- AWS Documentation and Well-Architected Framework
- HashiCorp Terraform Documentation
- WordPress Docker Official Image maintainers 
