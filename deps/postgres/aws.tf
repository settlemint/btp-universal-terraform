# AWS mode: Deploy PostgreSQL via RDS
# TODO: Implement AWS RDS PostgreSQL instance

# Placeholder for AWS RDS implementation
# resource "aws_db_instance" "postgres" {
#   count                = var.mode == "aws" ? 1 : 0
#   identifier           = var.aws.identifier
#   engine               = "postgres"
#   engine_version       = var.aws.engine_version
#   instance_class       = var.aws.instance_class
#   allocated_storage    = var.aws.allocated_storage
#   db_name              = var.aws.database
#   username             = var.aws.username
#   password             = var.aws.password
#   vpc_security_group_ids = var.aws.security_group_ids
#   db_subnet_group_name = var.aws.subnet_group_name
#   skip_final_snapshot  = var.aws.skip_final_snapshot
#
#   tags = {
#     Name = "btp-postgres"
#   }
# }

locals {
  aws_host     = var.mode == "aws" ? "rds-endpoint.region.rds.amazonaws.com" : null
  aws_port     = var.mode == "aws" ? 5432 : null
  aws_user     = var.mode == "aws" ? var.aws.username : null
  aws_password = var.mode == "aws" ? var.aws.password : null
  aws_database = var.mode == "aws" ? var.aws.database : null
}
