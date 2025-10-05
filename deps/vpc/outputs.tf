output "vpc_id" {
  description = "ID of the VPC"
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.mode == "aws" && var.aws.create_vpc ? aws_vpc.main[0].cidr_block : null
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = local.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = local.public_subnet_ids
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = local.rds_security_group_id
}

output "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache"
  value       = local.elasticache_security_group_id
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways"
  value       = var.mode == "aws" && var.aws.create_vpc && var.aws.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}
