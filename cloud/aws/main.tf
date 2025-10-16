locals {
  vpc_defaults = {
    create_vpc                             = true
    vpc_name                               = "btp-vpc"
    vpc_cidr                               = "10.0.0.0/16"
    region                                 = "us-east-1"
    availability_zones                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
    enable_nat_gateway                     = true
    single_nat_gateway                     = true
    enable_s3_endpoint                     = true
    additional_security_group_ids          = []
    existing_vpc_id                        = null
    existing_private_subnet_ids            = []
    existing_public_subnet_ids             = []
    existing_rds_security_group_id         = null
    existing_elasticache_security_group_id = null
  }

  vpc_input  = merge(local.vpc_defaults, try(var.vpc, {}))
  create_vpc = local.vpc_input.create_vpc
  azs        = local.vpc_input.availability_zones
  az_count   = length(local.azs)

  nat_gateway_count         = local.create_vpc && local.vpc_input.enable_nat_gateway && local.az_count > 0 ? (local.vpc_input.single_nat_gateway ? 1 : local.az_count) : 0
  private_route_table_count = local.create_vpc && local.vpc_input.enable_nat_gateway && local.az_count > 0 ? (local.vpc_input.single_nat_gateway ? 1 : local.az_count) : 0
}

resource "aws_vpc" "main" {
  count                = local.create_vpc ? 1 : 0
  cidr_block           = local.vpc_input.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = local.vpc_input.vpc_name
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name        = "${local.vpc_input.vpc_name}-igw"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = local.create_vpc ? local.az_count : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = cidrsubnet(local.vpc_input.vpc_cidr, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.vpc_input.vpc_name}-public-${local.azs[count.index]}"
    Type        = "public"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_subnet" "private" {
  count             = local.create_vpc ? local.az_count : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = cidrsubnet(local.vpc_input.vpc_cidr, 8, count.index + local.az_count)
  availability_zone = local.azs[count.index]

  tags = {
    Name        = "${local.vpc_input.vpc_name}-private-${local.azs[count.index]}"
    Type        = "private"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name        = "${local.vpc_input.vpc_name}-nat-eip-${count.index + 1}"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${local.vpc_input.vpc_name}-nat-${count.index + 1}"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  count  = local.create_vpc ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name        = "${local.vpc_input.vpc_name}-public-rt"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_route_table_association" "public" {
  count          = local.create_vpc ? local.az_count : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count  = local.private_route_table_count
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[local.vpc_input.single_nat_gateway ? 0 : count.index].id
  }

  tags = {
    Name        = "${local.vpc_input.vpc_name}-private-rt-${count.index + 1}"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_route_table_association" "private" {
  count          = local.create_vpc ? local.az_count : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = local.vpc_input.enable_nat_gateway && local.private_route_table_count > 0 ? aws_route_table.private[local.vpc_input.single_nat_gateway ? 0 : count.index].id : aws_route_table.public[0].id
}

resource "aws_security_group" "rds" {
  count       = local.create_vpc ? 1 : 0
  name        = "${local.vpc_input.vpc_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "PostgreSQL from VPC"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = [local.vpc_input.vpc_cidr]
    security_groups = local.vpc_input.additional_security_group_ids
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.vpc_input.vpc_name}-rds-sg"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_security_group" "elasticache" {
  count       = local.create_vpc ? 1 : 0
  name        = "${local.vpc_input.vpc_name}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description     = "Redis from VPC"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks     = [local.vpc_input.vpc_cidr]
    security_groups = local.vpc_input.additional_security_group_ids
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.vpc_input.vpc_name}-elasticache-sg"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_vpc_endpoint" "s3" {
  count        = local.create_vpc && local.vpc_input.enable_s3_endpoint ? 1 : 0
  vpc_id       = aws_vpc.main[0].id
  service_name = "com.amazonaws.${local.vpc_input.region}.s3"

  tags = {
    Name        = "${local.vpc_input.vpc_name}-s3-endpoint"
    ManagedBy   = "terraform"
    Application = "btp-vpc"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count           = local.create_vpc && local.vpc_input.enable_s3_endpoint ? local.private_route_table_count : 0
  route_table_id  = aws_route_table.private[local.vpc_input.single_nat_gateway ? 0 : count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

locals {
  vpc_id = local.vpc_input.create_vpc ? aws_vpc.main[0].id : local.vpc_input.existing_vpc_id

  private_subnet_ids = local.vpc_input.create_vpc ? aws_subnet.private[*].id : local.vpc_input.existing_private_subnet_ids
  public_subnet_ids  = local.vpc_input.create_vpc ? aws_subnet.public[*].id : local.vpc_input.existing_public_subnet_ids

  rds_security_group_id         = local.vpc_input.create_vpc ? aws_security_group.rds[0].id : local.vpc_input.existing_rds_security_group_id
  elasticache_security_group_id = local.vpc_input.create_vpc ? aws_security_group.elasticache[0].id : local.vpc_input.existing_elasticache_security_group_id

  nat_gateway_ips = local.vpc_input.create_vpc && local.vpc_input.enable_nat_gateway ? aws_eip.nat[*].public_ip : []

  network = {
    vpc_id             = local.vpc_id
    vpc_cidr           = local.vpc_input.create_vpc ? local.vpc_input.vpc_cidr : null
    private_subnet_ids = local.private_subnet_ids
    public_subnet_ids  = local.public_subnet_ids
    nat_gateway_ips    = local.nat_gateway_ips
  }

  security_groups = {
    rds         = local.rds_security_group_id
    elasticache = local.elasticache_security_group_id
  }

  k8s_context = {
    vpc_id                   = local.vpc_id
    subnet_ids               = local.private_subnet_ids
    control_plane_subnet_ids = local.private_subnet_ids
    security_group_ids       = []
  }

  dependency_context = {
    postgres = {
      subnet_ids         = local.private_subnet_ids
      security_group_ids = local.rds_security_group_id != null ? [local.rds_security_group_id] : []
    }
    redis = {
      subnet_ids         = local.private_subnet_ids
      security_group_ids = local.elasticache_security_group_id != null ? [local.elasticache_security_group_id] : []
    }
  }
}
