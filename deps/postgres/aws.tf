# AWS mode: Deploy PostgreSQL via RDS

locals {
  aws_subnet_ids = (
    length(try(var.aws.subnet_ids, [])) > 0 ?
    var.aws.subnet_ids :
    try(var.aws_network.subnet_ids, [])
  )

  aws_security_group_ids = (
    length(try(var.aws.security_group_ids, [])) > 0 ?
    var.aws.security_group_ids :
    try(var.aws_network.security_group_ids, [])
  )

  resolved_aws_password = coalesce(
    try(var.aws.password, null),
    try(var.secrets.password, null)
  )

  aws_subnet_group_name_value = try(var.aws.subnet_group_name, null)

  aws_subnet_group_candidates = compact([
    local.aws_subnet_group_name_value != null ? trimspace(local.aws_subnet_group_name_value) : null
  ])

  aws_subnet_group_name_provided = length(local.aws_subnet_group_candidates) > 0 ? local.aws_subnet_group_candidates[0] : null
  aws_manage_subnet_group        = var.mode == "aws" && local.aws_subnet_group_name_provided == null

  aws_config = merge(
    var.aws,
    {
      subnet_ids         = local.aws_subnet_ids
      security_group_ids = local.aws_security_group_ids
      subnet_group_name  = local.aws_manage_subnet_group ? null : local.aws_subnet_group_name_provided
      password           = local.resolved_aws_password
    }
  )
}

# Create DB subnet group if subnets are provided but no group name
resource "aws_db_subnet_group" "postgres" {
  count      = local.aws_manage_subnet_group ? 1 : 0
  name       = "${local.aws_config.identifier}-subnet-group"
  subnet_ids = local.aws_config.subnet_ids

  tags = {
    Name        = "${local.aws_config.identifier}-subnet-group"
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }
}

# Create parameter group to allow non-SSL connections (SSL is optional)
resource "aws_db_parameter_group" "postgres" {
  count  = var.mode == "aws" ? 1 : 0
  name   = "${local.aws_config.identifier}-pg"
  family = "postgres15"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = {
    Name        = "${local.aws_config.identifier}-parameter-group"
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  count                  = var.mode == "aws" ? 1 : 0
  identifier             = local.aws_config.identifier
  engine                 = "postgres"
  engine_version         = local.aws_config.engine_version
  instance_class         = local.aws_config.instance_class
  allocated_storage      = local.aws_config.allocated_storage
  db_name                = local.aws_config.database
  username               = local.aws_config.username
  password               = local.aws_config.password
  vpc_security_group_ids = local.aws_config.security_group_ids
  db_subnet_group_name   = local.aws_config.subnet_group_name != null ? local.aws_config.subnet_group_name : (length(aws_db_subnet_group.postgres) > 0 ? aws_db_subnet_group.postgres[0].name : null)
  parameter_group_name   = aws_db_parameter_group.postgres[0].name
  skip_final_snapshot    = local.aws_config.skip_final_snapshot
  publicly_accessible    = local.aws_config.publicly_accessible

  # Enable automated backups
  backup_retention_period = local.aws_config.backup_retention_period
  backup_window           = local.aws_config.backup_window

  # Enable encryption at rest
  storage_encrypted = local.aws_config.storage_encrypted
  kms_key_id        = local.aws_config.kms_key_id

  # Performance Insights
  enabled_cloudwatch_logs_exports = local.aws_config.enabled_cloudwatch_logs_exports
  performance_insights_enabled    = local.aws_config.performance_insights_enabled

  # Maintenance and upgrades
  auto_minor_version_upgrade = local.aws_config.auto_minor_version_upgrade
  maintenance_window         = local.aws_config.maintenance_window

  tags = {
    Name        = local.aws_config.identifier
    ManagedBy   = "terraform"
    Application = "btp-postgres"
  }
}

locals {
  aws_subnet_group_name_effective = var.mode == "aws" ? (
    local.aws_manage_subnet_group && length(aws_db_subnet_group.postgres) > 0 ?
    aws_db_subnet_group.postgres[0].name :
    local.aws_subnet_group_name_provided
  ) : null

  aws_host     = var.mode == "aws" ? aws_db_instance.postgres[0].address : null
  aws_port     = var.mode == "aws" ? aws_db_instance.postgres[0].port : null
  aws_user     = var.mode == "aws" ? aws_db_instance.postgres[0].username : null
  aws_password = var.mode == "aws" ? local.aws_config.password : null
  aws_database = var.mode == "aws" ? aws_db_instance.postgres[0].db_name : null
}
