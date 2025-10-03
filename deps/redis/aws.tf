# AWS mode: Deploy Redis via ElastiCache
# TODO: Implement AWS ElastiCache Redis cluster

# Placeholder for AWS ElastiCache implementation
# resource "aws_elasticache_cluster" "redis" {
#   count                = var.mode == "aws" ? 1 : 0
#   cluster_id           = var.aws.cluster_id
#   engine               = "redis"
#   engine_version       = var.aws.engine_version
#   node_type            = var.aws.node_type
#   num_cache_nodes      = 1
#   parameter_group_name = var.aws.parameter_group_name
#   port                 = 6379
#   security_group_ids   = var.aws.security_group_ids
#   subnet_group_name    = var.aws.subnet_group_name
# }

locals {
  aws_host        = var.mode == "aws" ? "redis-cluster.cache.amazonaws.com" : null
  aws_port        = var.mode == "aws" ? 6379 : null
  aws_password    = var.mode == "aws" ? var.aws.auth_token : null
  aws_scheme      = var.mode == "aws" ? "redis" : null
  aws_tls_enabled = var.mode == "aws" ? var.aws.transit_encryption_enabled : null
}
