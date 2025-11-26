# =============================================================================
# ALB Module
# =============================================================================
# Creates Application Load Balancer with HTTP to HTTPS redirect
# =============================================================================

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  enable_http2               = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
  })
}

# -----------------------------------------------------------------------------
# Target Group
# -----------------------------------------------------------------------------
# Routes traffic to ECS containers
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "main" {
  name        = "${var.name_prefix}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance" 

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200,301,302"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# HTTP Listener (Redirect to HTTPS)
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-http-listener"
  })
}

# -----------------------------------------------------------------------------
# HTTPS Listener
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-https-listener"
  })
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Load Balancer:
#   - internet-facing (internal = false)
#   - Deployed across 2 public subnets for HA
#   - HTTP/2 enabled for better performance
#   - Deletion protection disabled for easy cleanup (enable in prod)
#
# Target Group:
#   - target_type = "instance" for EC2 launch type
#   - Use "ip" for Fargate or awsvpc network mode
#   - Stickiness enabled for WordPress session handling
#
# Health Check:
#   - Checks root path "/" 
#   - Accepts 200, 301, 302 (WordPress may redirect)
#   - 30 second interval, 2 healthy / 3 unhealthy threshold
#   - Adjust path to "/wp-admin/install.php" if needed initially
#
# SSL Policy:
#   - ELBSecurityPolicy-TLS13-1-2-2021-06 supports TLS 1.2 and 1.3
#   - Strong cipher suites, good security rating
#   - See AWS docs for other policy options
#
# HTTP to HTTPS Redirect:
#   - All HTTP traffic redirected to HTTPS (301 permanent)
#   - Best practice for security and SEO
#
# Stickiness:
#   - Required for WordPress to maintain user sessions
#   - 24 hour cookie duration (86400 seconds)
#   - Uses ALB-generated cookie
#
# =============================================================================