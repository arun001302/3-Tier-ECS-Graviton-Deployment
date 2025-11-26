# =============================================================================
# Security Groups Module
# =============================================================================
# Centralized security groups to avoid circular dependencies
# =============================================================================

# -----------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------
# Allows: HTTP (80) and HTTPS (443) from anywhere
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-sg-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg-alb" 
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-http"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from anywhere"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-https"
  })
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow traffic to ECS instances"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.ecs.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-to-ecs"
  })
}

# -----------------------------------------------------------------------------
# ECS Security Group
# -----------------------------------------------------------------------------
# Allows: Traffic from ALB on container port
# Egress: All traffic (for pulling images, connecting to RDS, etc.)
# -----------------------------------------------------------------------------

resource "aws_security_group" "ecs" {
  name        = "${var.name_prefix}-sg-ecs"
  description = "Security group for ECS instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg-ecs"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Traffic from ALB"
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-from-alb"
  })
}

# Allow ephemeral ports for dynamic port mapping (if used)
resource "aws_vpc_security_group_ingress_rule" "ecs_ephemeral_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Ephemeral ports from ALB for dynamic port mapping"
  from_port                    = 32768
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-ephemeral-from-alb"
  })
}

resource "aws_vpc_security_group_egress_rule" "ecs_all_outbound" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-all-outbound"
  })
}

# -----------------------------------------------------------------------------
# RDS Security Group
# -----------------------------------------------------------------------------
# Allows: MySQL traffic from ECS instances only
# -----------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-sg-rds"
  description = "Security group for RDS MySQL"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sg-rds"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from ECS instances"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-from-ecs"
  })
}

resource "aws_vpc_security_group_egress_rule" "rds_outbound" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow outbound traffic (for RDS updates)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-outbound"
  })
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Security Group Design:
#   - ALB: Public-facing, accepts HTTP/HTTPS from internet
#   - ECS: Private, only accepts traffic from ALB
#   - RDS: Private, only accepts traffic from ECS
#
# Why centralized security groups?
#   - Avoids circular dependencies between modules
#   - Single place to audit all network rules
#   - Easier to modify access patterns
#
# Using aws_vpc_security_group_*_rule resources (not inline rules):
#   - More flexible and modular
#   - Can be modified without recreating security group
#   - Terraform best practice for production
#
# Ephemeral Ports (32768-65535):
#   - Required for ECS dynamic port mapping
#   - ECS assigns random high ports to containers
#   - ALB health checks need access to these ports
#
# =============================================================================