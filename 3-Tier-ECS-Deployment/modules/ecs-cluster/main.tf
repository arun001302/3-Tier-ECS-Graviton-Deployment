# =============================================================================
# ECS Cluster Module
# =============================================================================
# Creates ECS Cluster with EC2 Auto Scaling Group and Capacity Provider
# =============================================================================

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# ECS Cluster Capacity Providers
# -----------------------------------------------------------------------------

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

# -----------------------------------------------------------------------------
# ECS Capacity Provider
# -----------------------------------------------------------------------------

resource "aws_ecs_capacity_provider" "main" {
  name = "${var.name_prefix}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Launch Template for ECS EC2 Instances
# -----------------------------------------------------------------------------

resource "aws_launch_template" "ecs" {
  name          = "${var.name_prefix}-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = var.cluster_name
  }))

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-ecs-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-ecs-volume"
    })
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.name_prefix}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.min_instances
  max_size            = var.max_instances
  desired_capacity    = var.desired_instances

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  # Required for ECS Capacity Provider managed termination
  protect_from_scale_in = false

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Policies
# -----------------------------------------------------------------------------

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name_prefix}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name_prefix}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms for Auto Scaling
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Scale up when CPU exceeds 80%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Scale down when CPU below 20%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]

  tags = var.tags
}

# =============================================================================
# NOTES:
# =============================================================================
#
# ECS Cluster:
#   - Container Insights enabled for detailed monitoring
#   - Uses Capacity Provider for managed scaling
#
# Capacity Provider:
#   - Manages EC2 instance lifecycle automatically
#   - Scales instances based on task placement needs
#   - Target capacity 100% means keep instances fully utilized
#
# Launch Template:
#   - Uses ECS-optimized Amazon Linux 2023 ARM64 AMI
#   - IMDSv2 required (http_tokens = "required") for security
#   - No public IP (instances in private subnets)
#   - User data registers instance with ECS cluster
#
# Auto Scaling:
#   - Min: 2 instances (one per AZ for HA)
#   - Max: 4 instances (prevents runaway scaling)
#   - Scale up at 80% CPU, down at 20%
#   - 5 minute cooldown between scaling actions
#
# Instance Refresh:
#   - Rolling updates when launch template changes
#   - Maintains 50% healthy instances during refresh
#
# Tags:
#   - AmazonECSManaged tag required for Capacity Provider
#   - All tags propagated to instances and volumes
#
# =============================================================================