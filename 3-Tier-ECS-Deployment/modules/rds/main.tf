# =============================================================================
# RDS Module
# =============================================================================
# Creates RDS MySQL instance with Multi-AZ and Secrets Manager integration
# =============================================================================

# -----------------------------------------------------------------------------
# Random Password Generation
# -----------------------------------------------------------------------------

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# -----------------------------------------------------------------------------
# Secrets Manager - Store Database Credentials
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.name_prefix}-db-credentials"
  description             = "RDS MySQL credentials for ${var.name_prefix}"
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id 

  secret_string = jsonencode({
    username = var.username
    password = random_password.db_password.result
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "db-subnet-${var.name_prefix}"
  description = "Subnet group for ${var.name_prefix} RDS instance"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

# -----------------------------------------------------------------------------
# DB Parameter Group
# -----------------------------------------------------------------------------

resource "aws_db_parameter_group" "main" {
  name        = "db-params-${var.name_prefix}" 
  family      = "mysql8.0"
  description = "Parameter group for ${var.name_prefix} MySQL 8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# RDS MySQL Instance
# -----------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier = var.identifier

  # Engine Configuration
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.main.name

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database Configuration
  db_name  = var.db_name
  username = var.username
  password = random_password.db_password.result
  port     = 3306

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = true
  deletion_protection     = false

  # Monitoring
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  monitoring_interval             = 0

  # Performance Insights (disabled to save costs on t4g.micro)
  performance_insights_enabled = false

  tags = merge(var.tags, {
    Name = var.identifier
  })

  lifecycle {
    ignore_changes = [password]
  }
}