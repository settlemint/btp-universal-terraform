# AWS mode: Deploy Redis via ElastiCache

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

  aws_auth_token = coalesce(
    try(var.aws.auth_token, null),
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
      auth_token         = local.aws_auth_token
    }
  )
}

# Create cache subnet group if subnets are provided but no group name
resource "aws_elasticache_subnet_group" "redis" {
  count      = local.aws_manage_subnet_group ? 1 : 0
  name       = "${local.aws_config.cluster_id}-subnet-group"
  subnet_ids = local.aws_config.subnet_ids

  tags = {
    Name        = "${local.aws_config.cluster_id}-subnet-group"
    ManagedBy   = "terraform"
    Application = "btp-redis"
  }
}

# ElastiCache Redis replication group (required for auth_token support)
resource "aws_elasticache_replication_group" "redis" {
  count                      = var.mode == "aws" ? 1 : 0
  replication_group_id       = local.aws_config.cluster_id
  description                = "BTP Redis cache cluster"
  engine                     = "redis"
  engine_version             = local.aws_config.engine_version
  node_type                  = local.aws_config.node_type
  num_cache_clusters         = local.aws_config.num_cache_nodes
  parameter_group_name       = local.aws_config.parameter_group_name
  port                       = 6379
  security_group_ids         = local.aws_config.security_group_ids
  subnet_group_name          = local.aws_subnet_group_name_effective
  automatic_failover_enabled = local.aws_config.num_cache_nodes > 1 ? true : false

  # Transit encryption and authentication
  transit_encryption_enabled = local.aws_config.transit_encryption_enabled
  at_rest_encryption_enabled = local.aws_config.at_rest_encryption_enabled
  auth_token                 = local.aws_config.transit_encryption_enabled ? local.aws_config.auth_token : null

  # Maintenance and snapshots
  maintenance_window         = local.aws_config.maintenance_window
  snapshot_window            = local.aws_config.snapshot_window
  snapshot_retention_limit   = local.aws_config.snapshot_retention_limit
  auto_minor_version_upgrade = local.aws_config.auto_minor_version_upgrade

  # Apply immediately for dev, set to false for prod
  apply_immediately = local.aws_config.apply_immediately

  # Notifications
  notification_topic_arn = local.aws_config.notification_topic_arn

  tags = {
    Name        = local.aws_config.cluster_id
    ManagedBy   = "terraform"
    Application = "btp-redis"
  }
}

locals {
  aws_subnet_group_name_effective = var.mode == "aws" ? (
    local.aws_manage_subnet_group && length(aws_elasticache_subnet_group.redis) > 0 ?
    aws_elasticache_subnet_group.redis[0].name :
    local.aws_subnet_group_name_provided
  ) : null

  aws_host        = var.mode == "aws" ? aws_elasticache_replication_group.redis[0].primary_endpoint_address : null
  aws_port        = var.mode == "aws" ? 6379 : null
  aws_password    = var.mode == "aws" && local.aws_config.transit_encryption_enabled ? local.aws_config.auth_token : null
  aws_scheme      = var.mode == "aws" ? (local.aws_config.transit_encryption_enabled ? "rediss" : "redis") : null
  aws_tls_enabled = var.mode == "aws" ? local.aws_config.transit_encryption_enabled : null
}
