# =======================================================
# TERRAFORM VARIABLES
# =======================================================

# -------------------------------------------------------
# AWS Region
# -------------------------------------------------------

variable "aws_region" {
  description = "AWS region where the lab infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

# -------------------------------------------------------
# Project Name
# -------------------------------------------------------

variable "project_name" {
  description = "Name of the project."
  type        = string
  default     = "AWS-CloudFormation-Lab"
}

# -------------------------------------------------------
# Environment
# -------------------------------------------------------

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "lab"
}

# =======================================================
# NETWORK VARIABLES
# =======================================================

# -------------------------------------------------------
# VPC CIDR
# -------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.0.0.0/16"
}

# -------------------------------------------------------
# Availability Zones
# -------------------------------------------------------

variable "availability_zones" {
  description = "Availability Zones used by the lab."
  type        = list(string)

  default = [
    "us-east-1a",
    "us-east-1b"
  ]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "The lab requires exactly two Availability Zones."
  }
}

# -------------------------------------------------------
# Public Subnet CIDRs
# -------------------------------------------------------

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets."
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.4.0/24"
  ]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "The lab requires exactly two public subnet CIDRs."
  }
}

# -------------------------------------------------------
# Private Subnet CIDRs
# -------------------------------------------------------

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets."
  type        = list(string)

  default = [
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "The lab requires exactly two private subnet CIDRs."
  }
}

# =======================================================
# EC2 VARIABLES
# =======================================================

# -------------------------------------------------------
# EC2 AMI
# -------------------------------------------------------

variable "ami_id" {
  description = "AMI ID used by the EC2 web server."
  type        = string
}

# -------------------------------------------------------
# EC2 Instance Type
# -------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for the web server."
  type        = string
  default     = "t3.micro"
}

# -------------------------------------------------------
# EC2 Key Pair
# -------------------------------------------------------

variable "key_pair_name" {
  description = "Existing EC2 Key Pair used for SSH access."
  type        = string
}

# -------------------------------------------------------
# EC2 UserData Script
# -------------------------------------------------------

variable "userdata_script_url" {
  description = "Raw GitHub URL of the EC2 bootstrap script."
  type        = string
  default     = "https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/scripts/ec2-userdata.sh"
}

# =======================================================
# S3 VARIABLES
# =======================================================

# -------------------------------------------------------
# S3 Bucket Name
# -------------------------------------------------------
#
# Leave this empty to let AWS generate a unique bucket
# name.
#
# If you want a predictable bucket name, provide one.
# -------------------------------------------------------

variable "s3_bucket_name" {
  description = "Optional globally unique S3 bucket name. Leave empty for an AWS-generated name."
  type        = string
  default     = ""
}

# =======================================================
# RDS VARIABLES
# =======================================================

# -------------------------------------------------------
# RDS Database Name
# -------------------------------------------------------

variable "db_name" {
  description = "Initial MySQL database name."
  type        = string
  default     = "labdb"
}

# -------------------------------------------------------
# RDS Master Username
# -------------------------------------------------------

variable "db_username" {
  description = "RDS master username."
  type        = string
  default     = "admin"
}

# -------------------------------------------------------
# RDS Instance Class
# -------------------------------------------------------

variable "db_instance_class" {
  description = "RDS MySQL instance class."
  type        = string
  default     = "db.t3.micro"
}

# -------------------------------------------------------
# RDS Engine Version
# -------------------------------------------------------

variable "db_engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.0"
}

# -------------------------------------------------------
# RDS Storage
# -------------------------------------------------------

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
  default     = 20
}

# -------------------------------------------------------
# RDS Backup Retention
# -------------------------------------------------------

variable "db_backup_retention_period" {
  description = "Number of days to retain automated RDS backups."
  type        = number
  default     = 0
}

# -------------------------------------------------------
# RDS Storage Encryption
# -------------------------------------------------------

variable "db_storage_encrypted" {
  description = "Whether RDS storage encryption should be enabled."
  type        = bool
  default     = false
}

# -------------------------------------------------------
# RDS Deletion Protection
# -------------------------------------------------------

variable "db_deletion_protection" {
  description = "Whether RDS deletion protection should be enabled."
  type        = bool
  default     = false
}