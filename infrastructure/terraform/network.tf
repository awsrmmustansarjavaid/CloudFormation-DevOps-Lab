# =======================================================
# CHARLIE CAFE - TERRAFORM NETWORK INFRASTRUCTURE
# =======================================================
#
# File:
#   network.tf
#
# Purpose:
#   Creates the core VPC networking infrastructure for the
#   Charlie Cafe Terraform DevOps Lab.
#
# CloudFormation resources converted here:
#
#   AWS::EC2::VPC
#   AWS::EC2::InternetGateway
#   AWS::EC2::VPCGatewayAttachment
#   AWS::EC2::Subnet
#   AWS::EC2::RouteTable
#   AWS::EC2::Route
#   AWS::EC2::SubnetRouteTableAssociation
#
# =======================================================
#
# TERRAFORM NAMING CONVENTION
# =======================================================
#
# This Terraform infrastructure exists alongside the
# existing CloudFormation implementation of the same lab.
#
# Therefore AWS resource names use the Terraform-specific
# "CharlieCafe-TF" naming convention.
#
# Examples:
#
#   VPC:
#     CharlieCafe-TF-Lab-VPC
#
#   Internet Gateway:
#     CharlieCafe-TF-Lab-InternetGateway
#
#   Public Route Table:
#     CharlieCafe-TF-Public-RouteTable
#
#   Private Route Table:
#     CharlieCafe-TF-Private-RouteTable
#
#   Public Subnets:
#     CharlieCafe-TF-Public-Subnet-1
#     CharlieCafe-TF-Public-Subnet-2
#
#   Private Subnets:
#     CharlieCafe-TF-Private-Subnet-1
#     CharlieCafe-TF-Private-Subnet-2
#
# =======================================================
#
# ARCHITECTURE
# =======================================================
#
#                         INTERNET
#                             |
#                             |
#                    Internet Gateway
#                             |
#                             |
#                  +-------------------+
#                  | CharlieCafe-TF    |
#                  |      VPC           |
#                  +-------------------+
#                             |
#                 +-----------+-----------+
#                 |                       |
#                 v                       v
#             PUBLIC                  PRIVATE
#             SUBNETS                 SUBNETS
#                 |                       |
#                 v                       v
#          Public Route Table      Private Route Table
#                 |                       |
#                 v                       |
#              Internet                  X
#
# =======================================================
#
# IMPORTANT:
#
# No NAT Gateway is created.
#
# Therefore:
#
#   Public subnets:
#     Have internet connectivity through the Internet
#     Gateway.
#
#   Private subnets:
#     Do NOT have a default route to the internet.
#
# AWS service connectivity for private resources such as
# ECS can be provided through VPC endpoints created in
# ecs_ecr.tf.
#
# =======================================================


# =======================================================
# 1. VPC
# =======================================================
#
# Creates the main VPC for the Charlie Cafe Terraform lab.
#
# Terraform resource address:
#
#   aws_vpc.lab
#
# AWS Name tag:
#
#   CharlieCafe-TF-Lab-VPC
#
# =======================================================

resource "aws_vpc" "lab" {

  # -----------------------------------------------------
  # VPC CIDR
  # -----------------------------------------------------
  #
  # Defined in variables.tf.
  #
  # Default:
  #
  #   10.0.0.0/16
  #
  # -----------------------------------------------------

  cidr_block = var.vpc_cidr


  # -----------------------------------------------------
  # Enable DNS support
  # -----------------------------------------------------
  #
  # Required for normal AWS VPC DNS resolution.
  #
  # -----------------------------------------------------

  enable_dns_support = true


  # -----------------------------------------------------
  # Enable DNS hostnames
  # -----------------------------------------------------
  #
  # Allows resources inside the VPC to receive DNS
  # hostnames where applicable.
  #
  # -----------------------------------------------------

  enable_dns_hostnames = true


  # -----------------------------------------------------
  # Resource tags
  # -----------------------------------------------------

  tags = {

    # Terraform-specific VPC name.
    Name = "CharlieCafe-TF-Lab-VPC"

    # Project identification.
    Project = var.project_name

    # Environment identification.
    Environment = var.environment

    # Infrastructure management tool.
    ManagedBy = "Terraform"
  }
}


# =======================================================
# 2. INTERNET GATEWAY
# =======================================================
#
# Creates and attaches an Internet Gateway to the
# Charlie Cafe Terraform VPC.
#
# Terraform resource address:
#
#   aws_internet_gateway.lab
#
# AWS Name tag:
#
#   CharlieCafe-TF-Lab-InternetGateway
#
# =======================================================

resource "aws_internet_gateway" "lab" {

  # -----------------------------------------------------
  # Attach the Internet Gateway to our Terraform VPC.
  # -----------------------------------------------------

  vpc_id = aws_vpc.lab.id


  # -----------------------------------------------------
  # Resource tags
  # -----------------------------------------------------

  tags = {

    Name = "CharlieCafe-TF-Lab-InternetGateway"

    Project = var.project_name

    Environment = var.environment

    ManagedBy = "Terraform"
  }
}


# =======================================================
# 3. PUBLIC SUBNETS
# =======================================================
#
# Creates two public subnets.
#
# Public subnets are used by internet-facing resources
# such as the Application Load Balancer.
#
# Terraform resource addresses:
#
#   aws_subnet.public[0]
#   aws_subnet.public[1]
#
# Names are supplied by locals.tf:
#
#   CharlieCafe-TF-Public-Subnet-1
#   CharlieCafe-TF-Public-Subnet-2
#
# =======================================================

resource "aws_subnet" "public" {

  # Two public subnets.
  count = 2


  # -----------------------------------------------------
  # Existing Terraform VPC
  # -----------------------------------------------------

  vpc_id = aws_vpc.lab.id


  # -----------------------------------------------------
  # Public subnet CIDR
  # -----------------------------------------------------
  #
  # Values come from:
  #
  #   var.public_subnet_cidrs
  #
  # -----------------------------------------------------

  cidr_block = var.public_subnet_cidrs[count.index]


  # -----------------------------------------------------
  # Availability Zone
  # -----------------------------------------------------
  #
  # Values come from:
  #
  #   var.availability_zones
  #
  # -----------------------------------------------------

  availability_zone = var.availability_zones[count.index]


  # -----------------------------------------------------
  # Public IP assignment
  # -----------------------------------------------------
  #
  # Equivalent to CloudFormation:
  #
  #   MapPublicIpOnLaunch: true
  #
  # Instances launched into these subnets can receive
  # public IPv4 addresses when requested.
  #
  # -----------------------------------------------------

  map_public_ip_on_launch = true


  # -----------------------------------------------------
  # Resource tags
  # -----------------------------------------------------

  tags = {

    # Name comes from locals.tf.
    Name = local.public_subnet_names[count.index]

    # Identifies subnet tier.
    Tier = "Public"

    # Project identification.
    Project = var.project_name

    # Environment identification.
    Environment = var.environment

    # Infrastructure management tool.
    ManagedBy = "Terraform"
  }
}


# =======================================================
# 4. PRIVATE SUBNETS
# =======================================================
#
# Creates two private subnets.
#
# These subnets are intended for internal resources such
# as:
#
#   - ECS Fargate tasks
#   - RDS
#   - Other private application resources
#
# Terraform resource addresses:
#
#   aws_subnet.private[0]
#   aws_subnet.private[1]
#
# Names are supplied by locals.tf:
#
#   CharlieCafe-TF-Private-Subnet-1
#   CharlieCafe-TF-Private-Subnet-2
#
# =======================================================

resource "aws_subnet" "private" {

  # Two private subnets.
  count = 2


  # -----------------------------------------------------
  # Existing Terraform VPC
  # -----------------------------------------------------

  vpc_id = aws_vpc.lab.id


  # -----------------------------------------------------
  # Private subnet CIDR
  # -----------------------------------------------------

  cidr_block = var.private_subnet_cidrs[count.index]


  # -----------------------------------------------------
  # Availability Zone
  # -----------------------------------------------------

  availability_zone = var.availability_zones[count.index]


  # -----------------------------------------------------
  # Public IP assignment
  # -----------------------------------------------------
  #
  # Equivalent to CloudFormation:
  #
  #   MapPublicIpOnLaunch: false
  #
  # Resources launched here do not automatically receive
  # public IPv4 addresses.
  #
  # -----------------------------------------------------

  map_public_ip_on_launch = false


  # -----------------------------------------------------
  # Resource tags
  # -----------------------------------------------------

  tags = {

    # Name comes from locals.tf.
    Name = local.private_subnet_names[count.index]

    # Identifies subnet tier.
    Tier = "Private"

    # Project identification.
    Project = var.project_name

    # Environment identification.
    Environment = var.environment

    # Infrastructure management tool.
    ManagedBy = "Terraform"
  }
}


# =======================================================
# 5. PUBLIC ROUTE TABLE
# =======================================================
#
# Creates the route table used by both public subnets.
#
# Terraform resource address:
#
#   aws_route_table.public
#
# AWS Name tag:
#
#   CharlieCafe-TF-Public-RouteTable
#
# =======================================================

resource "aws_route_table" "public" {

  # -----------------------------------------------------
  # Associate the route table with the Terraform VPC.
  # -----------------------------------------------------

  vpc_id = aws_vpc.lab.id


  # -----------------------------------------------------
  # Resource tags
  # -----------------------------------------------------

  tags = {

    Name = "CharlieCafe-TF-Public-RouteTable"

    Project = var.project_name

    Environment = var.environment

    ManagedBy = "Terraform"
  }
}


# =======================================================
# 6. PUBLIC INTERNET ROUTE
# =======================================================
#
# Adds the default internet route:
#
#   0.0.0.0/0
#
# Traffic destined for the internet is sent through the
# Terraform-managed Internet Gateway.
#
# =======================================================

resource "aws_route" "public_internet" {

  # -----------------------------------------------------
  # Public route table
  # -----------------------------------------------------

  route_table_id = aws_route_table.public.id


  # -----------------------------------------------------
  # Default IPv4 internet route
  # -----------------------------------------------------

  destination_cidr_block = "0.0.0.0/0"


  # -----------------------------------------------------
  # Internet Gateway
  # -----------------------------------------------------

  gateway_id = aws_internet_gateway.lab.id
}


# =======================================================
# 7. PUBLIC SUBNET ROUTE TABLE ASSOCIATIONS
# =======================================================
#
# Associates both public subnets with the public route
# table.
#
# Result:
#
#   Public Subnet 1
#        |
#        +---- Public Route Table
#
#   Public Subnet 2
#        |
#        +---- Public Route Table
#
# =======================================================

resource "aws_route_table_association" "public" {

  # Two public subnet associations.
  count = 2


  # -----------------------------------------------------
  # Public subnet
  # -----------------------------------------------------

  subnet_id = aws_subnet.public[count.index].id


  # -----------------------------------------------------
  # Public route table
  # -----------------------------------------------------

  route_table_id = aws_route_table.public.id
}


# =======================================================
# 8. PRIVATE ROUTE TABLE
# =======================================================
#
# Creates the route table used by both private subnets.
#
# IMPORTANT:
#
# There is intentionally NO:
#
#   0.0.0.0/0
#
# route through an Internet Gateway or NAT Gateway.
#
# This preserves the original CloudFormation lab design.
#
# AWS Name tag:
#
#   CharlieCafe-TF-Private-RouteTable
#
# =======================================================

resource "aws_route_table" "private" {

  # -----------------------------------------------------
  # Associate the route table with the Terraform VPC.
  # -----------------------------------------------------

  vpc_id = aws_vpc.lab.id


  # -----------------------------------------------------
  # Resource tags
  # -----------------------------------------------------

  tags = {

    Name = "CharlieCafe-TF-Private-RouteTable"

    Project = var.project_name

    Environment = var.environment

    ManagedBy = "Terraform"
  }
}


# =======================================================
# 9. PRIVATE SUBNET ROUTE TABLE ASSOCIATIONS
# =======================================================
#
# Associates both private subnets with the private route
# table.
#
# Result:
#
#   Private Subnet 1
#        |
#        +---- Private Route Table
#
#   Private Subnet 2
#        |
#        +---- Private Route Table
#
# Since the private route table does not contain a default
# internet route, these subnets remain private.
#
# =======================================================

resource "aws_route_table_association" "private" {

  # Two private subnet associations.
  count = 2


  # -----------------------------------------------------
  # Private subnet
  # -----------------------------------------------------

  subnet_id = aws_subnet.private[count.index].id


  # -----------------------------------------------------
  # Private route table
  # -----------------------------------------------------

  route_table_id = aws_route_table.private.id
}


# =======================================================
# END OF network.tf
# =======================================================
#
# TERRAFORM RESOURCE NAMING SUMMARY
# =======================================================
#
# VPC:
#   CharlieCafe-TF-Lab-VPC
#
# Internet Gateway:
#   CharlieCafe-TF-Lab-InternetGateway
#
# Public Subnet 1:
#   CharlieCafe-TF-Public-Subnet-1
#
# Public Subnet 2:
#   CharlieCafe-TF-Public-Subnet-2
#
# Private Subnet 1:
#   CharlieCafe-TF-Private-Subnet-1
#
# Private Subnet 2:
#   CharlieCafe-TF-Private-Subnet-2
#
# Public Route Table:
#   CharlieCafe-TF-Public-RouteTable
#
# Private Route Table:
#   CharlieCafe-TF-Private-RouteTable
#
# =======================================================
#
# IMPORTANT:
#
# Terraform internal resource addresses such as:
#
#   aws_vpc.lab
#   aws_subnet.public
#   aws_subnet.private
#   aws_route_table.public
#   aws_route_table.private
#
# have intentionally NOT been renamed.
#
# These are Terraform configuration identifiers and are
# referenced by other .tf files. Changing them unnecessarily
# would require corresponding changes throughout the
# Terraform configuration and could also affect Terraform
# state/resource addressing.
#
# The AWS-visible names are controlled by the Name tags
# above.
#
# =======================================================

