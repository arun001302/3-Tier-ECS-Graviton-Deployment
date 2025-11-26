# =============================================================================
# ECS Service Module
# =============================================================================
# Creates ECS Task Definition, Service, and CloudWatch Log Group
# =============================================================================

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "ecs" {
  name              = var.log_group_name
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# -----------------------------------------------------------------------------
# ECS Task Definition
# -----------------------------------------------------------------------------

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name_prefix}-wordpress"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      essential = true
      cpu       = var.cpu
      memory    = var.memory

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = 0
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = var.wordpress_db_host
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.wordpress_db_name
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = var.wordpress_db_user
        },
        {
          name  = "WORDPRESS_TABLE_PREFIX"
          value = "wp_"
        }
      ]

      secrets = [
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "wordpress"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      mountPoints = []
      volumesFrom = []
    }
  ])

  tags = var.tags
}

# -----------------------------------------------------------------------------
# ECS Service
# -----------------------------------------------------------------------------

resource "aws_ecs_service" "main" {
  name                               = "${var.name_prefix}-service"
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  scheduling_strategy                = "REPLICA"
  enable_ecs_managed_tags            = true
  propagate_tags                     = "SERVICE"

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 100
    base              = 1
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Application Auto Scaling for ECS Service
# -----------------------------------------------------------------------------

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.desired_count * 3
  min_capacity       = var.desired_count
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name_prefix}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.name_prefix}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Task Definition:
#   - ARM64 architecture for Graviton instances
#   - Bridge network mode with dynamic port mapping
#   - Secrets injected from Secrets Manager (DB password)
#   - Container health check using curl
#
# Dynamic Port Mapping:
#   - hostPort = 0 lets Docker assign random port (32768-65535)
#   - ALB handles routing to dynamic ports
#   - Allows multiple tasks on same instance
#
# Service Configuration:
#   - Spread across AZs for high availability
#   - Spread across instances within AZ
#   - Circuit breaker auto-rollback on failed deployments
#   - 50% minimum healthy during deployments
#
# Auto Scaling:
#   - Scales tasks based on CPU and Memory utilization
#   - Target: 70% utilization
#   - Scale out quickly (60s), scale in slowly (300s)
#   - Min: desired_count, Max: 3x desired_count
#
# Deployment Circuit Breaker:
#   - Automatically rolls back failed deployments
#   - Detects when tasks keep failing to start
#   - Prevents bad deployments from taking down service
#
# Secrets:
#   - DB password pulled from Secrets Manager at runtime
#   - Format: ${secret_arn}:json_key::
#   - Never stored in task definition
#
# Health Check:
#   - Starts checking after 60 seconds (WordPress needs time to init)
#   - Checks every 30 seconds
#   - 3 consecutive failures marks unhealthy
#
# =============================================================================