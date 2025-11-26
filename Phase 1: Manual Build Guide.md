# Phase 1: Manual Build Guide

This guide walks you through building the entire 3-tier architecture manually using the AWS Console. By completing this phase, you'll understand how each AWS service works and how they integrate together—the same foundational knowledge that enterprise cloud engineers rely on daily.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [Step 1: Create the VPC and Networking](#step-1-create-the-vpc-and-networking)
- [Step 2: Create Security Groups](#step-2-create-security-groups)
- [Step 3: Create IAM Roles](#step-3-create-iam-roles)
- [Step 4: Create the RDS Database](#step-4-create-the-rds-database)
- [Step 5: Create the ECR Repository](#step-5-create-the-ecr-repository)
- [Step 6: Push WordPress Image to ECR](#step-6-push-wordpress-image-to-ecr)
- [Step 7: Create the ECS Cluster](#step-7-create-the-ecs-cluster)
- [Step 8: Create the Application Load Balancer](#step-8-create-the-application-load-balancer)
- [Step 9: Create the ECS Task Definition](#step-9-create-the-ecs-task-definition)
- [Step 10: Create the ECS Service](#step-10-create-the-ecs-service)
- [Step 11: Configure DNS with Route 53](#step-11-configure-dns-with-route-53)
- [Step 12: Verify the Deployment](#step-12-verify-the-deployment)
- [Cleanup](#-cleanup)

---

## 🎯 Overview

In this phase, you will manually create:

| Component | AWS Service | Purpose |
|-----------|-------------|---------|
| Network | VPC, Subnets, NAT Gateway | Isolated network with public/private tiers |
| Security | Security Groups, IAM Roles | Access control and permissions |
| Database | RDS MySQL | Managed database for WordPress |
| Container Registry | ECR | Store WordPress Docker image |
| Container Platform | ECS Cluster | Run WordPress containers |
| Load Balancer | ALB | Distribute traffic and SSL termination |
| DNS | Route 53 | Domain routing |

**Estimated Time:** 60-90 minutes

**Region:** us-east-1 (N. Virginia)

---

## ✅ Prerequisites

Before starting, ensure you have:

1. An AWS Account with administrator access
2. A domain name hosted in Route 53
3. AWS CLI installed and configured on your local machine
4. Docker installed on your local machine
5. Basic familiarity with the AWS Console

---

## Step 1: Create the VPC and Networking

The VPC provides network isolation for your application. We'll create public subnets for the load balancer and private subnets for the application and database tiers.

### 1.1 Create the VPC

1. Navigate to **VPC** in the AWS Console
2. Click **Create VPC**
3. Select **VPC and more** (this creates subnets, route tables, and gateways automatically)
4. Configure the following:

| Setting | Value |
|---------|-------|
| Name tag auto-generation | `3-tier-graviton` |
| IPv4 CIDR block | `10.0.0.0/16` |
| IPv6 CIDR block | No IPv6 CIDR block |
| Tenancy | Default |
| Number of Availability Zones | 2 |
| Number of public subnets | 2 |
| Number of private subnets | 2 |
| NAT gateways | In 1 AZ (cost optimization) |
| VPC endpoints | None |

5. Click **Create VPC**
6. Wait for all resources to be created (this takes 2-3 minutes)

### 1.2 Verify the Created Resources

After creation, verify you have:

- 1 VPC (`3-tier-graviton-vpc`)
- 2 Public subnets (`3-tier-graviton-subnet-public1-us-east-1a`, `3-tier-graviton-subnet-public2-us-east-1b`)
- 2 Private subnets (`3-tier-graviton-subnet-private1-us-east-1a`, `3-tier-graviton-subnet-private2-us-east-1b`)
- 1 Internet Gateway
- 1 NAT Gateway
- Route tables configured for public and private subnets

### 1.3 Note Your Resource IDs

Record the following IDs for later steps:

| Resource | ID (Example) |
|----------|--------------|
| VPC ID | `vpc-xxxxxxxxx` |
| Public Subnet 1 (us-east-1a) | `subnet-xxxxxxxxx` |
| Public Subnet 2 (us-east-1b) | `subnet-xxxxxxxxx` |
| Private Subnet 1 (us-east-1a) | `subnet-xxxxxxxxx` |
| Private Subnet 2 (us-east-1b) | `subnet-xxxxxxxxx` |

---

## Step 2: Create Security Groups

Security groups act as virtual firewalls. We'll create three security groups following the principle of least privilege.

### 2.1 Create ALB Security Group

1. Navigate to **VPC** > **Security Groups**
2. Click **Create security group**
3. Configure:

| Setting | Value |
|---------|-------|
| Security group name | `3-tier-graviton-sg-alb` |
| Description | `Security group for Application Load Balancer` |
| VPC | Select `3-tier-graviton-vpc` |

4. Add **Inbound rules**:

| Type | Port Range | Source | Description |
|------|------------|--------|-------------|
| HTTP | 80 | 0.0.0.0/0 | HTTP from anywhere |
| HTTPS | 443 | 0.0.0.0/0 | HTTPS from anywhere |

5. Leave Outbound rules as default (we'll update after creating ECS security group)
6. Click **Create security group**
7. Note the Security Group ID: `sg-xxxxxxxxx`

### 2.2 Create ECS Security Group

1. Click **Create security group**
2. Configure:

| Setting | Value |
|---------|-------|
| Security group name | `3-tier-graviton-sg-ecs` |
| Description | `Security group for ECS instances` |
| VPC | Select `3-tier-graviton-vpc` |

3. Add **Inbound rules**:

| Type | Port Range | Source | Description |
|------|------------|--------|-------------|
| Custom TCP | 32768-65535 | sg-xxxxxxxxx (ALB SG) | Ephemeral ports from ALB |
| Custom TCP | 80 | sg-xxxxxxxxx (ALB SG) | HTTP from ALB |

4. Leave Outbound rules as default (All traffic - required for pulling images, connecting to RDS)
5. Click **Create security group**
6. Note the Security Group ID: `sg-xxxxxxxxx`

### 2.3 Create RDS Security Group

1. Click **Create security group**
2. Configure:

| Setting | Value |
|---------|-------|
| Security group name | `3-tier-graviton-sg-rds` |
| Description | `Security group for RDS MySQL` |
| VPC | Select `3-tier-graviton-vpc` |

3. Add **Inbound rules**:

| Type | Port Range | Source | Description |
|------|------------|--------|-------------|
| MYSQL/Aurora | 3306 | sg-xxxxxxxxx (ECS SG) | MySQL from ECS instances |

4. Leave Outbound rules as default
5. Click **Create security group**

### 2.4 Update ALB Security Group Outbound Rules

This step is critical—the ALB must be able to reach ECS instances on ephemeral ports.

1. Go back to the ALB Security Group (`3-tier-graviton-sg-alb`)
2. Click **Edit outbound rules**
3. Delete the default "All traffic" rule
4. Add new outbound rules:

| Type | Port Range | Destination | Description |
|------|------------|-------------|-------------|
| Custom TCP | 32768-65535 | sg-xxxxxxxxx (ECS SG) | Ephemeral ports to ECS |
| Custom TCP | 80 | sg-xxxxxxxxx (ECS SG) | HTTP to ECS |

5. Click **Save rules**

---

## Step 3: Create IAM Roles

ECS requires specific IAM roles for task execution and EC2 instance management.

### 3.1 Create ECS Task Execution Role

This role allows ECS to pull images from ECR and write logs to CloudWatch.

1. Navigate to **IAM** > **Roles**
2. Click **Create role**
3. Configure:

| Setting | Value |
|---------|-------|
| Trusted entity type | AWS service |
| Use case | Elastic Container Service |
| Use case selection | Elastic Container Service Task |

4. Click **Next**
5. Search and attach these policies:
   - `AmazonECSTaskExecutionRolePolicy`
   - `SecretsManagerReadWrite` (for database credentials)

6. Click **Next**
7. Enter Role name: `ecsTaskExecutionRole`
8. Click **Create role**

### 3.2 Create ECS Instance Role

This role allows EC2 instances to register with the ECS cluster.

1. Click **Create role**
2. Configure:

| Setting | Value |
|---------|-------|
| Trusted entity type | AWS service |
| Use case | EC2 |

3. Click **Next**
4. Search and attach these policies:
   - `AmazonEC2ContainerServiceforEC2Role`
   - `AmazonSSMManagedInstanceCore` (for Session Manager access)
   - `CloudWatchAgentServerPolicy`

5. Click **Next**
6. Enter Role name: `ecsInstanceRole`
7. Click **Create role**

### 3.3 Create Instance Profile for ECS Instance Role

1. In the IAM console, go to **Roles**
2. Find and click on `ecsInstanceRole`
3. The instance profile is automatically created with the same name when you create a role for EC2

---

## Step 4: Create the RDS Database

We'll create a MySQL database with Multi-AZ for high availability.

### 4.1 Create a DB Subnet Group

1. Navigate to **RDS** > **Subnet groups**
2. Click **Create DB subnet group**
3. Configure:

| Setting | Value |
|---------|-------|
| Name | `3-tier-graviton-db-subnet-group` |
| Description | `Subnet group for 3-tier Graviton RDS` |
| VPC | Select `3-tier-graviton-vpc` |

4. Under **Add subnets**:
   - Select Availability Zones: `us-east-1a`, `us-east-1b`
   - Select the **private subnets** only

5. Click **Create**

### 4.2 Create the RDS Instance

1. Navigate to **RDS** > **Databases**
2. Click **Create database**
3. Configure:

**Engine options:**
| Setting | Value |
|---------|-------|
| Engine type | MySQL |
| Version | MySQL 8.0.x (latest) |

**Templates:**
| Setting | Value |
|---------|-------|
| Template | Production |

**Availability and durability:**
| Setting | Value |
|---------|-------|
| Deployment options | Multi-AZ DB instance |

**Settings:**
| Setting | Value |
|---------|-------|
| DB instance identifier | `mysql-3-tier-graviton` |
| Master username | `wpadmin` |
| Master password | Choose a strong password and save it |

**Instance configuration:**
| Setting | Value |
|---------|-------|
| DB instance class | Burstable classes - `db.t4g.micro` |

**Storage:**
| Setting | Value |
|---------|-------|
| Storage type | gp3 |
| Allocated storage | 20 GiB |
| Enable storage autoscaling | Yes |
| Maximum storage threshold | 40 GiB |

**Connectivity:**
| Setting | Value |
|---------|-------|
| VPC | `3-tier-graviton-vpc` |
| DB subnet group | `3-tier-graviton-db-subnet-group` |
| Public access | No |
| VPC security group | Choose existing - `3-tier-graviton-sg-rds` |
| Availability Zone | No preference |

**Database authentication:**
| Setting | Value |
|---------|-------|
| Authentication | Password authentication |

**Additional configuration:**
| Setting | Value |
|---------|-------|
| Initial database name | `wordpress` |
| Enable automated backups | Yes |
| Backup retention period | 7 days |
| Enable encryption | Yes |

4. Click **Create database**
5. Wait for the database to be created (this takes 10-15 minutes)

### 4.3 Store Database Credentials in Secrets Manager

1. Navigate to **Secrets Manager**
2. Click **Store a new secret**
3. Configure:

| Setting | Value |
|---------|-------|
| Secret type | Credentials for Amazon RDS database |
| Username | `wpadmin` |
| Password | Your RDS password |
| Database | Select your RDS instance |

4. Click **Next**
5. Secret name: `3-tier-graviton-db-credentials`
6. Click **Next**, then **Next** again
7. Click **Store**
8. Note the Secret ARN for later use

### 4.4 Note the RDS Endpoint

1. Go back to **RDS** > **Databases**
2. Click on your database
3. Under **Connectivity & security**, note the **Endpoint** (e.g., `mysql-3-tier-graviton.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com`)

---

## Step 5: Create the ECR Repository

ECR will store your WordPress Docker image.

1. Navigate to **ECR** (Elastic Container Registry)
2. Click **Create repository**
3. Configure:

| Setting | Value |
|---------|-------|
| Visibility | Private |
| Repository name | `3-tier-graviton-wordpress` |
| Tag immutability | Disabled |
| Scan on push | Enabled |

4. Click **Create repository**
5. Note the Repository URI (e.g., `914261932225.dkr.ecr.us-east-1.amazonaws.com/3-tier-graviton-wordpress`)

---

## Step 6: Push WordPress Image to ECR

Now we'll pull the official WordPress ARM64 image and push it to your ECR repository.

### 6.1 Authenticate Docker to ECR

Open your terminal and run:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
```

Replace `<your-account-id>` with your AWS account ID.

You should see: `Login Succeeded`

### 6.2 Pull WordPress ARM64 Image

```bash
docker pull --platform linux/arm64 wordpress:latest
```

### 6.3 Tag and Push to ECR

```bash
# Tag the image
docker tag wordpress:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/3-tier-graviton-wordpress:latest

# Push to ECR
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/3-tier-graviton-wordpress:latest
```

### 6.4 Verify the Image in ECR

1. Go back to **ECR** in the AWS Console
2. Click on your repository
3. Verify the `latest` tag is present

---

## Step 7: Create the ECS Cluster

The ECS cluster will orchestrate your WordPress containers on Graviton EC2 instances.

### 7.1 Create the Cluster

1. Navigate to **ECS** (Elastic Container Service)
2. Click **Create cluster**
3. Configure:

| Setting | Value |
|---------|-------|
| Cluster name | `3-tier-graviton-cluster` |

**Infrastructure:**
| Setting | Value |
|---------|-------|
| Infrastructure | Amazon EC2 instances |

**Auto Scaling group:**
| Setting | Value |
|---------|-------|
| Provisioning model | On-Demand |
| Container instance Amazon Machine Image | Amazon Linux 2023 |
| EC2 instance type | t4g.medium |
| Desired capacity | Minimum: 2, Maximum: 4 |
| SSH Key pair | Select or create one (optional) |

**Network settings for EC2 instances:**
| Setting | Value |
|---------|-------|
| VPC | `3-tier-graviton-vpc` |
| Subnets | Select both **private** subnets |
| Security group | Use existing - `3-tier-graviton-sg-ecs` |
| Auto-assign public IP | Turn off |

**Monitoring:**
| Setting | Value |
|---------|-------|
| Container Insights | Turn on |

4. Click **Create**
5. Wait for the cluster to be created (2-3 minutes)

### 7.2 Verify EC2 Instances

1. Navigate to **EC2** > **Instances**
2. You should see 2 instances with the name `ECS Instance - 3-tier-graviton-cluster`
3. Verify they are:
   - Instance type: `t4g.medium`
   - State: Running
   - In private subnets

---

## Step 8: Create the Application Load Balancer

The ALB will distribute traffic and handle SSL termination.

### 8.1 Request an SSL Certificate

1. Navigate to **Certificate Manager** (ACM)
2. Click **Request a certificate**
3. Select **Request a public certificate**
4. Click **Next**
5. Configure:

| Setting | Value |
|---------|-------|
| Domain name | `wp.yourdomain.com` |
| Validation method | DNS validation |

6. Click **Request**
7. Click on the certificate to view details
8. Click **Create records in Route 53** to auto-validate
9. Wait for status to change to **Issued** (usually 5-10 minutes)

### 8.2 Create Target Group

1. Navigate to **EC2** > **Target Groups**
2. Click **Create target group**
3. Configure:

**Basic configuration:**
| Setting | Value |
|---------|-------|
| Target type | Instances |
| Target group name | `3-tier-graviton-tg` |
| Protocol | HTTP |
| Port | 80 |
| VPC | `3-tier-graviton-vpc` |
| Protocol version | HTTP1 |

**Health checks:**
| Setting | Value |
|---------|-------|
| Health check protocol | HTTP |
| Health check path | `/` |
| Healthy threshold | 2 |
| Unhealthy threshold | 3 |
| Timeout | 10 seconds |
| Interval | 30 seconds |
| Success codes | 200,301,302 |

4. Click **Next**
5. Don't register any targets yet (ECS will do this automatically)
6. Click **Create target group**

### 8.3 Create the Application Load Balancer

1. Navigate to **EC2** > **Load Balancers**
2. Click **Create load balancer**
3. Select **Application Load Balancer**
4. Click **Create**
5. Configure:

**Basic configuration:**
| Setting | Value |
|---------|-------|
| Load balancer name | `3-tier-graviton-alb` |
| Scheme | Internet-facing |
| IP address type | IPv4 |

**Network mapping:**
| Setting | Value |
|---------|-------|
| VPC | `3-tier-graviton-vpc` |
| Mappings | Select both **public** subnets |

**Security groups:**
| Setting | Value |
|---------|-------|
| Security groups | `3-tier-graviton-sg-alb` |

**Listeners and routing:**

Add two listeners:

| Listener | Port | Default action |
|----------|------|----------------|
| HTTP | 80 | Redirect to HTTPS://#{host}:443/#{path}?#{query} |
| HTTPS | 443 | Forward to `3-tier-graviton-tg` |

For the HTTPS listener:
- Select your ACM certificate from the dropdown

6. Click **Create load balancer**
7. Wait for the ALB to become **Active**
8. Note the **DNS name** (e.g., `3-tier-graviton-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com`)

---

## Step 9: Create the ECS Task Definition

The task definition describes how your WordPress container should run.

### 9.1 Create Task Definition

1. Navigate to **ECS** > **Task Definitions**
2. Click **Create new task definition**
3. Select **Create new task definition with JSON**
4. Replace the content with:

```json
{
  "family": "3-tier-graviton-wordpress",
  "networkMode": "bridge",
  "requiresCompatibilities": ["EC2"],
  "cpu": "512",
  "memory": "1024",
  "runtimePlatform": {
    "cpuArchitecture": "ARM64",
    "operatingSystemFamily": "LINUX"
  },
  "executionRoleArn": "arn:aws:iam::<your-account-id>:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "wordpress",
      "image": "<your-account-id>.dkr.ecr.us-east-1.amazonaws.com/3-tier-graviton-wordpress:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 0,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "WORDPRESS_DB_HOST",
          "value": "<your-rds-endpoint>"
        },
        {
          "name": "WORDPRESS_DB_NAME",
          "value": "wordpress"
        },
        {
          "name": "WORDPRESS_DB_USER",
          "value": "wpadmin"
        }
      ],
      "secrets": [
        {
          "name": "WORDPRESS_DB_PASSWORD",
          "valueFrom": "<your-secret-arn>:password::"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/3-tier-graviton-wordpress",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "wordpress",
          "awslogs-create-group": "true"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost/ || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

5. Replace the placeholders:
   - `<your-account-id>` - Your AWS account ID
   - `<your-rds-endpoint>` - Your RDS endpoint
   - `<your-secret-arn>` - Your Secrets Manager secret ARN

6. Click **Create**

---

## Step 10: Create the ECS Service

The ECS service maintains the desired number of WordPress containers.

### 10.1 Create Service

1. Navigate to **ECS** > **Clusters** > `3-tier-graviton-cluster`
2. In the **Services** tab, click **Create**
3. Configure:

**Environment:**
| Setting | Value |
|---------|-------|
| Compute options | Launch type |
| Launch type | EC2 |

**Deployment configuration:**
| Setting | Value |
|---------|-------|
| Task definition | `3-tier-graviton-wordpress` |
| Service name | `3-tier-graviton-service` |
| Desired tasks | 2 |

**Load balancing:**
| Setting | Value |
|---------|-------|
| Load balancer type | Application Load Balancer |
| Load balancer | Select `3-tier-graviton-alb` |
| Listener | Select `443:HTTPS` |
| Target group | Select `3-tier-graviton-tg` |
| Container name : port | `wordpress:80` |

4. Click **Create**
5. Wait for the service to start tasks

### 10.2 Verify Tasks are Running

1. Click on the service name
2. Go to the **Tasks** tab
3. Verify 2 tasks are in **RUNNING** status
4. Check the **Health status** shows **HEALTHY**

---

## Step 11: Configure DNS with Route 53

Point your domain to the Application Load Balancer.

### 11.1 Create DNS Record

1. Navigate to **Route 53** > **Hosted zones**
2. Click on your domain
3. Click **Create record**
4. Configure:

| Setting | Value |
|---------|-------|
| Record name | `wp` (or your chosen subdomain) |
| Record type | A |
| Alias | Yes |
| Route traffic to | Alias to Application and Classic Load Balancer |
| Region | US East (N. Virginia) |
| Load balancer | Select `3-tier-graviton-alb` |

5. Click **Create records**

---

## Step 12: Verify the Deployment

### 12.1 Test the Application

1. Open your browser and navigate to `https://wp.yourdomain.com`
2. You should see the WordPress installation page
3. Complete the WordPress setup wizard

### 12.2 Verify High Availability

1. Navigate to **ECS** > **Clusters** > **3-tier-graviton-cluster**
2. Check that tasks are distributed across both Availability Zones
3. Navigate to **EC2** > **Target Groups** > **3-tier-graviton-tg**
4. Verify both targets show **healthy** status

### 12.3 Check Logs

1. Navigate to **CloudWatch** > **Log groups**
2. Click on `/ecs/3-tier-graviton-wordpress`
3. Review logs to ensure WordPress is running without errors

---

## 🧹 Cleanup

To avoid ongoing charges, delete resources in this order:

1. **ECS Service:** Delete the service (set desired tasks to 0 first)
2. **ECS Cluster:** Delete the cluster
3. **RDS:** Delete the database (skip final snapshot for dev)
4. **ALB:** Delete the load balancer
5. **Target Group:** Delete the target group
6. **ECR:** Delete the repository and images
7. **NAT Gateway:** Delete the NAT gateway
8. **Elastic IPs:** Release any allocated Elastic IPs
9. **VPC:** Delete the VPC (this removes subnets, route tables, etc.)
10. **IAM Roles:** Delete the created roles
11. **Secrets Manager:** Delete the secret
12. **CloudWatch Logs:** Delete the log group
13. **ACM Certificate:** Delete the certificate (optional)

---

## 🎉 Congratulations!

You've successfully built an enterprise-style 3-tier architecture on AWS. You now understand:

- How VPCs provide network isolation
- How security groups control traffic flow
- How ECS orchestrates containers on EC2
- How ALB distributes traffic and terminates SSL
- How RDS provides managed database services
- How IAM roles enable secure service-to-service communication

---
