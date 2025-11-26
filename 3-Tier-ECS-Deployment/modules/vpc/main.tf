# =============================================================================
# VPC Module
# =============================================================================
# Creates a production-ready VPC with public and private subnets
# =============================================================================

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
# Allows public subnets to communicate with the internet
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# -----------------------------------------------------------------------------
# Public Subnets
# -----------------------------------------------------------------------------
# Hosts: ALB, NAT Gateway
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "Public"
  })
}

# -----------------------------------------------------------------------------
# Private Subnets
# -----------------------------------------------------------------------------
# Hosts: ECS instances, RDS
# -----------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
    Tier = "Private"
  })
}

# -----------------------------------------------------------------------------
# Elastic IPs for NAT Gateway
# -----------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"

  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${var.name_prefix}-nat-eip" : "${var.name_prefix}-nat-eip-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------------------------
# Allows private subnets to access the internet (outbound only)
# Single NAT Gateway mode saves ~$32/month but reduces availability
# -----------------------------------------------------------------------------

resource "aws_nat_gateway" "main" {
  count = var.single_nat_gateway ? 1 : length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${var.name_prefix}-nat" : "${var.name_prefix}-nat-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Public Route Table
# -----------------------------------------------------------------------------
# Routes internet traffic through Internet Gateway
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rt-public"
  })
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Private Route Tables
# -----------------------------------------------------------------------------
# Routes internet traffic through NAT Gateway
# One route table per AZ if using multiple NAT Gateways
# -----------------------------------------------------------------------------

resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${var.name_prefix}-rt-private" : "${var.name_prefix}-rt-private-${var.availability_zones[count.index]}"
  })
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# =============================================================================
# NOTES:
# =============================================================================
#
# Architecture:
#   - 2 Public Subnets (one per AZ) - for ALB and NAT Gateway
#   - 2 Private Subnets (one per AZ) - for ECS instances and RDS
#   - 1 or 2 NAT Gateways depending on single_nat_gateway variable
#
# Single NAT Gateway:
#   - Pros: Saves ~$32/month
#   - Cons: Single point of failure, cross-AZ traffic charges
#   - Recommendation: Use for dev/staging, not production
#
# DNS Settings:
#   - enable_dns_hostnames: Allows instances to get public DNS names
#   - enable_dns_support: Enables DNS resolution within VPC
#   - Both required for RDS to be accessible via endpoint name
#
# =============================================================================