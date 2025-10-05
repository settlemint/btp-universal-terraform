# VPC Module - Creates a dedicated VPC for BTP infrastructure
# Only creates VPC resources when mode = "aws" and create_vpc = true

# Main VPC
resource "aws_vpc" "main" {
  count                = var.mode == "aws" && var.aws.create_vpc ? 1 : 0
  cidr_block           = var.aws.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.aws.vpc_name
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
  count  = var.mode == "aws" && var.aws.create_vpc ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name        = "${var.aws.vpc_name}-igw"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# Public subnets (for NAT gateways and load balancers)
resource "aws_subnet" "public" {
  count                   = var.mode == "aws" && var.aws.create_vpc ? length(var.aws.availability_zones) : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(var.aws.vpc_cidr, 8, count.index)
  availability_zone       = var.aws.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.aws.vpc_name}-public-${var.aws.availability_zones[count.index]}"
    Type        = "public"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# Private subnets (for RDS, ElastiCache, etc.)
resource "aws_subnet" "private" {
  count             = var.mode == "aws" && var.aws.create_vpc ? length(var.aws.availability_zones) : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = cidrsubnet(var.aws.vpc_cidr, 8, count.index + length(var.aws.availability_zones))
  availability_zone = var.aws.availability_zones[count.index]

  tags = {
    Name        = "${var.aws.vpc_name}-private-${var.aws.availability_zones[count.index]}"
    Type        = "private"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.mode == "aws" && var.aws.create_vpc && var.aws.enable_nat_gateway ? (var.aws.single_nat_gateway ? 1 : length(var.aws.availability_zones)) : 0
  domain = "vpc"

  tags = {
    Name        = "${var.aws.vpc_name}-nat-eip-${count.index + 1}"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways for private subnet internet access
resource "aws_nat_gateway" "main" {
  count         = var.mode == "aws" && var.aws.create_vpc && var.aws.enable_nat_gateway ? (var.aws.single_nat_gateway ? 1 : length(var.aws.availability_zones)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.aws.vpc_name}-nat-${count.index + 1}"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route table for public subnets
resource "aws_route_table" "public" {
  count  = var.mode == "aws" && var.aws.create_vpc ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name        = "${var.aws.vpc_name}-public-rt"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count          = var.mode == "aws" && var.aws.create_vpc ? length(var.aws.availability_zones) : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  count  = var.mode == "aws" && var.aws.create_vpc ? (var.aws.single_nat_gateway ? 1 : length(var.aws.availability_zones)) : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[var.aws.single_nat_gateway ? 0 : count.index].id
  }

  tags = {
    Name        = "${var.aws.vpc_name}-private-rt-${count.index + 1}"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count          = var.mode == "aws" && var.aws.create_vpc ? length(var.aws.availability_zones) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.aws.single_nat_gateway ? 0 : count.index].id
}

# Security group for RDS
resource "aws_security_group" "rds" {
  count       = var.mode == "aws" && var.aws.create_vpc ? 1 : 0
  name        = "${var.aws.vpc_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "PostgreSQL from VPC"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = [var.aws.vpc_cidr]
    security_groups = var.aws.additional_security_group_ids
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.aws.vpc_name}-rds-sg"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# Security group for ElastiCache
resource "aws_security_group" "elasticache" {
  count       = var.mode == "aws" && var.aws.create_vpc ? 1 : 0
  name        = "${var.aws.vpc_name}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "Redis from VPC"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks     = [var.aws.vpc_cidr]
    security_groups = var.aws.additional_security_group_ids
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.aws.vpc_name}-elasticache-sg"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# VPC Endpoints for S3 (optional, reduces data transfer costs)
resource "aws_vpc_endpoint" "s3" {
  count        = var.mode == "aws" && var.aws.create_vpc && var.aws.enable_s3_endpoint ? 1 : 0
  vpc_id       = aws_vpc.main[0].id
  service_name = "com.amazonaws.${var.aws.region}.s3"

  tags = {
    Name        = "${var.aws.vpc_name}-s3-endpoint"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

# Associate S3 endpoint with route tables
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count           = var.mode == "aws" && var.aws.create_vpc && var.aws.enable_s3_endpoint ? length(aws_route_table.private) : 0
  route_table_id  = aws_route_table.private[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

# Outputs for use by other modules
locals {
  vpc_id = var.mode == "aws" ? (
    var.aws.create_vpc ? aws_vpc.main[0].id : var.aws.existing_vpc_id
  ) : null

  private_subnet_ids = var.mode == "aws" ? (
    var.aws.create_vpc ? aws_subnet.private[*].id : var.aws.existing_private_subnet_ids
  ) : []

  public_subnet_ids = var.mode == "aws" ? (
    var.aws.create_vpc ? aws_subnet.public[*].id : var.aws.existing_public_subnet_ids
  ) : []

  rds_security_group_id = var.mode == "aws" ? (
    var.aws.create_vpc ? aws_security_group.rds[0].id : var.aws.existing_rds_security_group_id
  ) : null

  elasticache_security_group_id = var.mode == "aws" ? (
    var.aws.create_vpc ? aws_security_group.elasticache[0].id : var.aws.existing_elasticache_security_group_id
  ) : null
}
