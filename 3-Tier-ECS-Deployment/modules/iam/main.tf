# =============================================================================
# IAM Module
# =============================================================================
# Creates IAM roles and policies for ECS
# =============================================================================

# -----------------------------------------------------------------------------
# ECS Task Execution Role
# -----------------------------------------------------------------------------
# Used by ECS agent to:
#   - Pull images from ECR
#   - Write logs to CloudWatch
#   - Retrieve secrets from Secrets Manager
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_execution" {
  name = "${var.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policy for basic ECS execution
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.name_prefix}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:${var.name_prefix}*"
      }
    ]
  })
}

# Custom policy for CloudWatch Logs
resource "aws_iam_role_policy" "ecs_execution_logs" {
  name = "${var.name_prefix}-ecs-execution-logs"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:${var.log_group_name}:*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# ECS Task Role
# -----------------------------------------------------------------------------
# Used by the application container itself to:
#   - Access AWS services (S3, SES, etc.) if needed
#   - Currently minimal permissions
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_task" {
  name = "${var.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Task role policy - add permissions here if WordPress needs AWS access
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.name_prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# EC2 Instance Role for ECS
# -----------------------------------------------------------------------------
# Used by EC2 instances in the ECS cluster to:
#   - Register with ECS cluster
#   - Pull images from ECR
#   - Send logs to CloudWatch
#   - Allow SSM Session Manager access
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ecs_instance" {
  name = "${var.name_prefix}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed policy for ECS EC2 instances
resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attach SSM policy for Session Manager access (debugging)
resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy for instance metrics
resource "aws_iam_role_policy_attachment" "ecs_instance_cloudwatch" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${var.name_prefix}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name

  tags = var.tags
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Three Roles Explained:
#
# 1. ECS Execution Role (ecs_execution):
#    - Used BY ECS (not your container)
#    - Pulls images, writes logs, fetches secrets
#    - Required for all ECS tasks
#
# 2. ECS Task Role (ecs_task):
#    - Used BY your container/application
#    - Add permissions here if WordPress needs AWS access
#    - Example: S3 for media uploads, SES for email
#
# 3. EC2 Instance Role (ecs_instance):
#    - Used BY the EC2 instance hosting containers
#    - Registers instance with ECS cluster
#    - Includes SSM for secure shell access (no SSH keys needed)
#
# Least Privilege:
#    - Secrets Manager: Only secrets with project prefix
#    - CloudWatch Logs: Only specific log group
#    - Expand permissions as needed
#
# SSM Session Manager:
#    - Secure alternative to SSH
#    - No need to open port 22 or manage SSH keys
#    - Access via: aws ssm start-session --target <instance-id>
#
# =============================================================================