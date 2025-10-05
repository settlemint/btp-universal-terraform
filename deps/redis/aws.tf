# AWS mode: Deploy Redis via ElastiCache

# Generate a random auth token if transit encryption is enabled and no token provided
resource "random_password" "redis_auth_token" {
  count   = var.mode == "aws" && var.aws.transit_encryption_enabled && var.aws.auth_token == null ? 1 : 0
  length  = 32
  special = true
  # ElastiCache auth token has specific character requirements
  override_special = "!&#$^<>-"
}

# Create cache subnet group if subnets are provided but no group name
resource "aws_elasticache_subnet_group" "redis" {
  count      = var.mode == "aws" && var.aws.subnet_group_name == null && length(var.aws.subnet_ids) > 0 ? 1 : 0
  name       = "${var.aws.cluster_id}-subnet-group"
  subnet_ids = var.aws.subnet_ids

  tags = {
    Name        = "${var.aws.cluster_id}-subnet-group"
    ManagedBy   = "terraform"
    Application = "btp-redis"
  }
}

# ElastiCache Redis replication group (required for auth_token support)
resource "aws_elasticache_replication_group" "redis" {
  count                      = var.mode == "aws" ? 1 : 0
  replication_group_id       = var.aws.cluster_id
  description                = "BTP Redis cache cluster"
  engine                     = "redis"
  engine_version             = var.aws.engine_version
  node_type                  = var.aws.node_type
  num_cache_clusters         = var.aws.num_cache_nodes
  parameter_group_name       = var.aws.parameter_group_name
  port                       = 6379
  security_group_ids         = var.aws.security_group_ids
  subnet_group_name          = var.aws.subnet_group_name != null ? var.aws.subnet_group_name : (length(var.aws.subnet_ids) > 0 ? aws_elasticache_subnet_group.redis[0].name : null)
  automatic_failover_enabled = var.aws.num_cache_nodes > 1 ? true : false

  # Transit encryption and authentication
  transit_encryption_enabled = var.aws.transit_encryption_enabled
  at_rest_encryption_enabled = var.aws.at_rest_encryption_enabled
  auth_token                 = var.aws.transit_encryption_enabled ? (var.aws.auth_token != null ? var.aws.auth_token : random_password.redis_auth_token[0].result) : null

  # Maintenance and snapshots
  maintenance_window         = var.aws.maintenance_window
  snapshot_window            = var.aws.snapshot_window
  snapshot_retention_limit   = var.aws.snapshot_retention_limit
  auto_minor_version_upgrade = var.aws.auto_minor_version_upgrade

  # Apply immediately for dev, set to false for prod
  apply_immediately = var.aws.apply_immediately

  # Notifications
  notification_topic_arn = var.aws.notification_topic_arn

  tags = {
    Name        = var.aws.cluster_id
    ManagedBy   = "terraform"
    Application = "btp-redis"
  }
}

locals {
  aws_host        = var.mode == "aws" ? aws_elasticache_replication_group.redis[0].primary_endpoint_address : null
  aws_port        = var.mode == "aws" ? 6379 : null
  aws_password    = var.mode == "aws" && var.aws.transit_encryption_enabled ? (var.aws.auth_token != null ? var.aws.auth_token : random_password.redis_auth_token[0].result) : null
  aws_scheme      = var.mode == "aws" ? (var.aws.transit_encryption_enabled ? "rediss" : "redis") : null
  aws_tls_enabled = var.mode == "aws" ? var.aws.transit_encryption_enabled : null
}
