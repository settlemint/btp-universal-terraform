# AWS mode: Deploy PostgreSQL via RDS

# Create DB subnet group if subnets are provided but no group name
resource "aws_db_subnet_group" "postgres" {
  count      = var.mode == "aws" && var.aws.subnet_group_name == null && length(var.aws.subnet_ids) > 0 ? 1 : 0
  name       = "${var.aws.identifier}-subnet-group"
  subnet_ids = var.aws.subnet_ids

  tags = {
    Name        = "${var.aws.identifier}-subnet-group"
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }
}

# Create parameter group to allow non-SSL connections (SSL is optional)
resource "aws_db_parameter_group" "postgres" {
  count  = var.mode == "aws" ? 1 : 0
  name   = "${var.aws.identifier}-pg"
  family = "postgres15"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = {
    Name        = "${var.aws.identifier}-parameter-group"
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  count                  = var.mode == "aws" ? 1 : 0
  identifier             = var.aws.identifier
  engine                 = "postgres"
  engine_version         = var.aws.engine_version
  instance_class         = var.aws.instance_class
  allocated_storage      = var.aws.allocated_storage
  db_name                = var.aws.database
  username               = var.aws.username
  password               = var.aws.password
  vpc_security_group_ids = var.aws.security_group_ids
  db_subnet_group_name   = var.aws.subnet_group_name != null ? var.aws.subnet_group_name : (length(var.aws.subnet_ids) > 0 ? aws_db_subnet_group.postgres[0].name : null)
  parameter_group_name   = aws_db_parameter_group.postgres[0].name
  skip_final_snapshot    = var.aws.skip_final_snapshot
  publicly_accessible    = var.aws.publicly_accessible

  # Enable automated backups
  backup_retention_period = var.aws.backup_retention_period
  backup_window           = var.aws.backup_window

  # Enable encryption at rest
  storage_encrypted = var.aws.storage_encrypted
  kms_key_id        = var.aws.kms_key_id

  # Performance Insights
  enabled_cloudwatch_logs_exports = var.aws.enabled_cloudwatch_logs_exports
  performance_insights_enabled    = var.aws.performance_insights_enabled

  # Maintenance and upgrades
  auto_minor_version_upgrade = var.aws.auto_minor_version_upgrade
  maintenance_window         = var.aws.maintenance_window

  tags = {
    Name        = var.aws.identifier
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }
}

locals {
  aws_host     = var.mode == "aws" ? aws_db_instance.postgres[0].address : null
  aws_port     = var.mode == "aws" ? aws_db_instance.postgres[0].port : null
  aws_user     = var.mode == "aws" ? aws_db_instance.postgres[0].username : null
  aws_password = var.mode == "aws" ? var.aws.password : null
  aws_database = var.mode == "aws" ? aws_db_instance.postgres[0].db_name : null
}
