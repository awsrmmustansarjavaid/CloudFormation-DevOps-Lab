# =======================================================
# NETWORK INFRASTRUCTURE
# =======================================================
#
# CloudFormation resources converted here:
#
# AWS::EC2::VPC
# AWS::EC2::InternetGateway
# AWS::EC2::VPCGatewayAttachment
# AWS::EC2::Subnet
# AWS::EC2::RouteTable
# AWS::EC2::Route
# AWS::EC2::SubnetRouteTableAssociation
#
# Architecture:
#
#                  Internet
#                     |
#              Internet Gateway
#                     |
#                    VPC
#                     |
#          +----------+----------+
#          |                     |
#       Public                Private
#       Subnets               Subnets
#          |                     |
#    Public Route Table    Private Route Table
#
# NOTE:
# No NAT Gateway is created.
# Therefore private subnets have no direct internet route.
# =======================================================


# =======================================================
# VPC
# =======================================================

resource "aws_vpc" "lab" {

  # -----------------------------------------------------
  # VPC CIDR
  # -----------------------------------------------------

  cidr_block = var.vpc_cidr

  # -----------------------------------------------------
  # Enable DNS support
  # -----------------------------------------------------

  enable_dns_support = true

  # -----------------------------------------------------
  # Enable DNS hostnames
  # -----------------------------------------------------

  enable_dns_hostnames = true

  tags = {
    Name = "Lab-VPC"
  }
}


# =======================================================
# INTERNET GATEWAY
# =======================================================

resource "aws_internet_gateway" "lab" {

  # Attach the Internet Gateway to our VPC.
  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "Lab-InternetGateway"
  }
}


# =======================================================
# PUBLIC SUBNETS
# =======================================================

resource "aws_subnet" "public" {

  count = 2

  vpc_id = aws_vpc.lab.id

  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  # Equivalent to:
  #
  # MapPublicIpOnLaunch: true
  #
  map_public_ip_on_launch = true

  tags = {
    Name = local.public_subnet_names[count.index]
    Tier = "Public"
  }
}


# =======================================================
# PRIVATE SUBNETS
# =======================================================

resource "aws_subnet" "private" {

  count = 2

  vpc_id = aws_vpc.lab.id

  cidr_block = var.private_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  # Equivalent to:
  #
  # MapPublicIpOnLaunch: false
  #
  map_public_ip_on_launch = false

  tags = {
    Name = local.private_subnet_names[count.index]
    Tier = "Private"
  }
}


# =======================================================
# PUBLIC ROUTE TABLE
# =======================================================

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "Public-RouteTable"
  }
}


# =======================================================
# PUBLIC INTERNET ROUTE
# =======================================================

resource "aws_route" "public_internet" {

  route_table_id = aws_route_table.public.id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.lab.id
}


# =======================================================
# PUBLIC SUBNET ASSOCIATIONS
# =======================================================

resource "aws_route_table_association" "public" {

  count = 2

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}


# =======================================================
# PRIVATE ROUTE TABLE
# =======================================================
#
# No default internet route is configured.
# This intentionally matches the CloudFormation lab.
# =======================================================

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.lab.id

  tags = {
    Name = "Private-RouteTable"
  }
}


# =======================================================
# PRIVATE SUBNET ASSOCIATIONS
# =======================================================

resource "aws_route_table_association" "private" {

  count = 2

  subnet_id = aws_subnet.private[count.index].id

  route_table_id = aws_route_table.private.id
}