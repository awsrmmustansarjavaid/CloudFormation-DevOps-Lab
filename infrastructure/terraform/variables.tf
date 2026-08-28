# =====================================================================
# CHARLIE CAFE - AWS TERRAFORM DEVOPS LAB
# TERRAFORM INPUT VARIABLES
# =====================================================================
#
# File:
#   terraform/variables.tf
#
# Purpose:
#   Defines all configurable input variables used by the Terraform
#   infrastructure for the Charlie Cafe AWS DevOps Lab.
#
# =====================================================================
# IMPORTANT RESOURCE NAMING CONVENTION
# =====================================================================
#
# This Terraform project exists alongside a separate CloudFormation
# implementation of the same Charlie Cafe lab.
#
# To prevent naming conflicts between the Terraform and CloudFormation
# infrastructures, Terraform-created AWS resources should use:
#
#   TF
#
# as their unique naming identifier.
#
# Recommended naming pattern:
#
#   CharlieCafe-TF-<Resource>
#
# Examples:
#
#   CharlieCafe-TF-VPC
#   CharlieCafe-TF-InternetGateway
#   CharlieCafe-TF-PublicSubnet-1
#   CharlieCafe-TF-PrivateSubnet-1
#   CharlieCafe-TF-ALB
#   CharlieCafe-TF-TargetGroup
#   CharlieCafe-TF-Cluster
#   CharlieCafe-TF-Service
#   CharlieCafe-TF-Task
#   CharlieCafe-TF-CloudFormation-ServiceRole
#
# IMPORTANT:
#
# The "TF" naming convention is intentionally applied to AWS resource
# names/defaults. Terraform internal resource addresses do NOT need
# to contain "TF".
#
# For example:
#
#   resource "aws_vpc" "main" { ... }
#
# can remain:
#
#   aws_vpc.main
#
# while the actual AWS resource name can be:
#
#   CharlieCafe-TF-VPC
#
# This keeps Terraform code clean while making AWS resources clearly
# identifiable.
#
# =====================================================================
#
# Design principles:
#   - Keep environment-specific values configurable.
#   - Avoid hard-coding AWS resource IDs where possible.
#   - Provide safe defaults for non-sensitive configuration.
#   - Keep secrets OUT of this file.
#   - Sensitive values should be supplied through AWS Secrets Manager,
#     GitHub Actions secrets, environment variables, or tfvars files.
#
# IMPORTANT:
#
#   Do NOT put passwords, access keys, secret keys, or database
#   credentials in this file.
#
# =====================================================================


# =====================================================================
# AWS PROVIDER / GENERAL PROJECT VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# AWS Region
# ---------------------------------------------------------------------
#
# AWS region where the Terraform infrastructure will be deployed.
#
# Default:
#   us-east-1
#
# You can override this using:
#
#   terraform apply -var="aws_region=us-east-1"
#
# or:
#
#   TF_VAR_aws_region=us-east-1
#
# ---------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where the Terraform lab infrastructure will be deployed."

  type    = string
  default = "us-east-1"

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "AWS region must not be empty."
  }
}


# ---------------------------------------------------------------------
# Project Name
# ---------------------------------------------------------------------
#
# Logical project name used for resource naming and tagging.
#
# IMPORTANT:
#
#   The project name now explicitly identifies this infrastructure
#   as the Terraform implementation.
#
# ---------------------------------------------------------------------

variable "project_name" {
  description = "Name of the AWS Terraform project."

  type    = string
  default = "CharlieCafe-TF-Lab"

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "Project name must not be empty."
  }
}


# ---------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------
#
# Environment identifier.
#
# Examples:
#   lab
#   dev
#   staging
#   production
#
# The default is Terraform-specific so it is easy to distinguish
# Terraform resources from CloudFormation resources.
#
# ---------------------------------------------------------------------

variable "environment" {
  description = "Environment name used for Terraform resource naming and tagging."

  type    = string
  default = "tf-lab"

  validation {
    condition = contains(
      ["lab", "dev", "development", "staging", "prod", "production", "tf-lab"],
      lower(var.environment)
    )

    error_message = "Environment must be one of: lab, dev, development, staging, prod, production, tf-lab."
  }
}


# =====================================================================
# NETWORK VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# VPC CIDR
# ---------------------------------------------------------------------
#
# Primary CIDR block for the Charlie Cafe Terraform VPC.
#
# Default:
#   10.0.0.0/16
#
# ---------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the Charlie Cafe Terraform VPC."

  type    = string
  default = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}


# ---------------------------------------------------------------------
# Availability Zones
# ---------------------------------------------------------------------
#
# Two Availability Zones are used for high availability.
#
# Default:
#   us-east-1a
#   us-east-1b
#
# IMPORTANT:
#   These Availability Zones must belong to the selected AWS region.
#
# ---------------------------------------------------------------------

variable "availability_zones" {
  description = "Two Availability Zones used by the Charlie Cafe Terraform infrastructure."

  type = list(string)

  default = [
    "us-east-1a",
    "us-east-1b"
  ]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "The Terraform lab requires exactly two Availability Zones."
  }

  validation {
    condition = alltrue([
      for az in var.availability_zones :
      length(trimspace(az)) > 0
    ])

    error_message = "Availability Zone names must not be empty."
  }
}


# ---------------------------------------------------------------------
# Public Subnet CIDRs
# ---------------------------------------------------------------------
#
# CIDR ranges for the two public subnets.
#
# Public subnet 1:
#   10.0.1.0/24
#
# Public subnet 2:
#   10.0.4.0/24
#
# ---------------------------------------------------------------------

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two Terraform public subnets."

  type = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.4.0/24"
  ]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "The Terraform lab requires exactly two public subnet CIDRs."
  }

  validation {
    condition = alltrue([
      for cidr in var.public_subnet_cidrs :
      can(cidrnetmask(cidr))
    ])

    error_message = "Every public subnet CIDR must be a valid IPv4 CIDR block."
  }
}


# ---------------------------------------------------------------------
# Private Subnet CIDRs
# ---------------------------------------------------------------------
#
# CIDR ranges for the two private subnets.
#
# Private subnet 1:
#   10.0.2.0/24
#
# Private subnet 2:
#   10.0.3.0/24
#
# These subnets can be used for resources such as RDS and ECS tasks.
#
# ---------------------------------------------------------------------

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two Terraform private subnets."

  type = list(string)

  default = [
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "The Terraform lab requires exactly two private subnet CIDRs."
  }

  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs :
      can(cidrnetmask(cidr))
    ])

    error_message = "Every private subnet CIDR must be a valid IPv4 CIDR block."
  }
}


# =====================================================================
# EC2 VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# EC2 AMI ID
# ---------------------------------------------------------------------
#
# AMI used by the Terraform-managed EC2 web server.
#
# IMPORTANT:
#
#   AMI IDs are REGION-SPECIFIC.
#
# Therefore, a universal hard-coded AMI ID is intentionally NOT used.
#
# The recommended approach is to provide this value from the
# Terraform deployment workflow or use a data source in main.tf to
# dynamically locate the appropriate Amazon Linux AMI.
#
# Example:
#
#   terraform apply -var="ami_id=ami-xxxxxxxxxxxxxxxxx"
#
# GitHub Actions can also provide:
#
#   TF_VAR_ami_id
#
# ---------------------------------------------------------------------

variable "ami_id" {
  description = "AMI ID used by the Terraform-managed EC2 web server. Provide a valid AMI ID for the selected AWS region."

  type    = string
  default = ""

  validation {
    condition = (
      var.ami_id == "" ||
      can(regex("^ami-[a-zA-Z0-9]+$", var.ami_id))
    )

    error_message = "ami_id must be empty or a valid AWS AMI ID such as ami-0123456789abcdef0."
  }
}


# ---------------------------------------------------------------------
# EC2 Instance Type
# ---------------------------------------------------------------------
#
# Instance size for the Terraform-managed EC2 web server.
#
# Default:
#   t3.micro
#
# ---------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type used by the Terraform-managed web server."

  type    = string
  default = "t3.micro"

  validation {
    condition     = length(trimspace(var.instance_type)) > 0
    error_message = "EC2 instance type must not be empty."
  }
}


# ---------------------------------------------------------------------
# EC2 Key Pair
# ---------------------------------------------------------------------
#
# Existing EC2 Key Pair used for SSH access.
#
# IMPORTANT:
#   The key pair must already exist in the selected AWS region.
#
# For production environments, SSH access should preferably be
# minimized or replaced with AWS Systems Manager Session Manager.
#
# ---------------------------------------------------------------------

variable "key_pair_name" {
  description = "Existing EC2 Key Pair name used for SSH access by the Terraform-managed server."

  type    = string
  default = ""

  validation {
    condition     = length(trimspace(var.key_pair_name)) > 0
    error_message = "key_pair_name must contain the name of an existing EC2 Key Pair."
  }
}


# ---------------------------------------------------------------------
# EC2 UserData Script URL
# ---------------------------------------------------------------------
#
# Raw GitHub URL containing the EC2 bootstrap script.
#
# The script can install packages, configure Docker/Nginx, pull the
# application code, and perform other initialization tasks.
#
# ---------------------------------------------------------------------

variable "userdata_script_url" {
  description = "Raw GitHub URL of the Terraform EC2 bootstrap/UserData script."

  type = string

  default = "https://raw.githubusercontent.com/awsrmmustansarjavaid/CloudFormation-DevOps-Lab/main/scripts/ec2-userdata.sh"

  validation {
    condition = (
      var.userdata_script_url == "" ||
      can(regex("^https://", var.userdata_script_url))
    )

    error_message = "userdata_script_url must be an HTTPS URL."
  }
}


# =====================================================================
# S3 VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# S3 Application Bucket Name
# ---------------------------------------------------------------------
#
# Optional S3 bucket used by the Terraform-managed application.
#
# Empty string means the Terraform configuration can generate or
# determine a suitable bucket name, depending on the implementation
# in the Terraform configuration.
#
# IMPORTANT:
#
#   S3 bucket names are globally unique across AWS.
#
# A Terraform-specific bucket name should preferably include:
#
#   tf
#
# Example:
#
#   charlie-cafe-tf-xxxxxxxx
#
# ---------------------------------------------------------------------

variable "s3_bucket_name" {
  description = "Optional globally unique S3 bucket name for the Terraform-managed application."

  type    = string
  default = ""

  validation {
    condition = (
      var.s3_bucket_name == "" ||
      (
        length(var.s3_bucket_name) >= 3 &&
        length(var.s3_bucket_name) <= 63 &&
        can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.s3_bucket_name))
      )
    )

    error_message = "s3_bucket_name must be empty or a valid S3 bucket name between 3 and 63 characters using lowercase letters, numbers, dots, and hyphens."
  }
}


# =====================================================================
# RDS / MYSQL VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# Database Name
# ---------------------------------------------------------------------

variable "db_name" {
  description = "Initial MySQL database name used by the Terraform-managed RDS instance."

  type    = string
  default = "tflabdb"

  validation {
    condition = can(regex(
      "^[A-Za-z][A-Za-z0-9_]*$",
      var.db_name
    ))

    error_message = "db_name must start with a letter and contain only letters, numbers, and underscores."
  }
}


# ---------------------------------------------------------------------
# RDS Master Username
# ---------------------------------------------------------------------
#
# IMPORTANT:
#   This is only the username.
#
#   The database password should NOT be stored in variables.tf.
#
#   Use AWS Secrets Manager for the password.
#
# ---------------------------------------------------------------------

variable "db_username" {
  description = "RDS MySQL master username for the Terraform-managed database."

  type    = string
  default = "admin"

  validation {
    condition = (
      length(var.db_username) >= 1 &&
      length(var.db_username) <= 16
    )

    error_message = "db_username must be between 1 and 16 characters."
  }
}


# ---------------------------------------------------------------------
# RDS Instance Class
# ---------------------------------------------------------------------
#
# Default:
#   db.t3.micro
#
# Suitable for a small development/lab workload.
#
# ---------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS MySQL DB instance class for the Terraform-managed database."

  type    = string
  default = "db.t3.micro"

  validation {
    condition     = length(trimspace(var.db_instance_class)) > 0
    error_message = "db_instance_class must not be empty."
  }
}


# ---------------------------------------------------------------------
# RDS Engine Version
# ---------------------------------------------------------------------
#
# MySQL engine version.
#
# IMPORTANT:
#   The exact supported versions depend on the AWS region and RDS.
#
# ---------------------------------------------------------------------

variable "db_engine_version" {
  description = "MySQL engine version for the Terraform-managed RDS database."

  type    = string
  default = "8.0"

  validation {
    condition     = length(trimspace(var.db_engine_version)) > 0
    error_message = "db_engine_version must not be empty."
  }
}


# ---------------------------------------------------------------------
# RDS Allocated Storage
# ---------------------------------------------------------------------
#
# Storage size in GB.
#
# ---------------------------------------------------------------------

variable "db_allocated_storage" {
  description = "Initial RDS allocated storage in GB for the Terraform-managed database."

  type    = number
  default = 20

  validation {
    condition     = var.db_allocated_storage >= 20
    error_message = "RDS allocated storage must be at least 20 GB."
  }
}


# ---------------------------------------------------------------------
# RDS Backup Retention
# ---------------------------------------------------------------------
#
# Number of days automated backups are retained.
#
# 0 means automated backup retention is disabled.
#
# ---------------------------------------------------------------------

variable "db_backup_retention_period" {
  description = "Number of days to retain automated RDS backups for the Terraform-managed database. Use 0 for the lab to disable retention."

  type    = number
  default = 0

  validation {
    condition = (
      var.db_backup_retention_period >= 0 &&
      var.db_backup_retention_period <= 35
    )

    error_message = "RDS backup retention period must be between 0 and 35 days."
  }
}


# ---------------------------------------------------------------------
# RDS Storage Encryption
# ---------------------------------------------------------------------
#
# Whether RDS storage encryption is enabled.
#
# Default is false to keep the lab configuration simple and cost-aware.
#
# For production workloads, encryption should normally be enabled.
#
# ---------------------------------------------------------------------

variable "db_storage_encrypted" {
  description = "Whether storage encryption should be enabled for the Terraform-managed RDS database."

  type    = bool
  default = false
}


# ---------------------------------------------------------------------
# RDS Deletion Protection
# ---------------------------------------------------------------------
#
# Prevents accidental deletion of the RDS database.
#
# Default:
#   false
#
# This is appropriate for a disposable Terraform lab.
#
# ---------------------------------------------------------------------

variable "db_deletion_protection" {
  description = "Whether RDS deletion protection should be enabled for the Terraform-managed database."

  type    = bool
  default = false
}


# =====================================================================
# CLOUDFORMATION TEMPLATE S3 BUCKET
# =====================================================================
#
# This bucket stores CloudFormation nested-stack templates used by
# the Charlie Cafe infrastructure.
#
# IMPORTANT:
#
# This does NOT mean Terraform resources are being replaced by
# CloudFormation.
#
# Terraform is simply managing the S3 bucket that stores templates.
#
# The bucket itself should still receive a Terraform-specific name
# so it cannot be confused with a bucket created by the separate
# CloudFormation implementation.
#
# Example:
#
#   charlie-cafe-tf-cfn-templates-xxxxxxxx
#
# ---------------------------------------------------------------------


variable "template_bucket_name" {
  description = "Globally unique S3 bucket name used by the Terraform-managed CloudFormation template storage."

  type    = string
  default = ""

  validation {
    condition = (
      var.template_bucket_name == "" ||
      (
        length(var.template_bucket_name) >= 3 &&
        length(var.template_bucket_name) <= 63 &&
        can(regex(
          "^[a-z0-9][a-z0-9.-]*[a-z0-9]$",
          var.template_bucket_name
        ))
      )
    )

    error_message = "template_bucket_name must be empty or a valid globally unique S3 bucket name between 3 and 63 characters."
  }
}


# =====================================================================
# ECS / ECR VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# Application Name
# ---------------------------------------------------------------------
#
# Logical application name used by Terraform-managed ECS, ECR, ALB
# and related resources.
#
# IMPORTANT:
#
# The default application name now includes the Terraform identifier.
#
# ---------------------------------------------------------------------

variable "application_name" {
  description = "Application name used for Terraform-managed ECS, ECR, ALB and related AWS resources."

  type    = string
  default = "CharlieCafe-TF"

  validation {
    condition = can(regex(
      "^[A-Za-z][A-Za-z0-9-]*$",
      var.application_name
    ))

    error_message = "application_name must start with a letter and contain only letters, numbers, and hyphens."
  }
}


# ---------------------------------------------------------------------
# ECR Repository Name
# ---------------------------------------------------------------------
#
# ECR repository containing the Terraform-managed Charlie Cafe
# Docker image.
#
# ECR repository names must use lowercase characters.
#
# Terraform-specific naming:
#
#   charlie-cafe-tf
#
# ---------------------------------------------------------------------

variable "ecr_repository_name" {
  description = "Amazon ECR repository name for the Terraform-managed Charlie Cafe Docker image."

  type    = string
  default = "charlie-cafe-tf"

  validation {
    condition = can(regex(
      "^[a-z0-9]+(?:[._/-][a-z0-9]+)*$",
      var.ecr_repository_name
    ))

    error_message = "ecr_repository_name contains invalid characters."
  }
}


# ---------------------------------------------------------------------
# ECS Cluster Name
# ---------------------------------------------------------------------
#
# Terraform-managed ECS cluster.
#
# ---------------------------------------------------------------------

variable "ecs_cluster_name" {
  description = "Amazon ECS cluster name for the Terraform-managed Charlie Cafe infrastructure."

  type    = string
  default = "CharlieCafe-TF-Cluster"

  validation {
    condition     = length(trimspace(var.ecs_cluster_name)) > 0
    error_message = "ecs_cluster_name must not be empty."
  }
}


# ---------------------------------------------------------------------
# ECS Service Name
# ---------------------------------------------------------------------
#
# Terraform-managed ECS service.
#
# ---------------------------------------------------------------------

variable "ecs_service_name" {
  description = "Amazon ECS service name for the Terraform-managed Charlie Cafe infrastructure."

  type    = string
  default = "CharlieCafe-TF-Service"

  validation {
    condition     = length(trimspace(var.ecs_service_name)) > 0
    error_message = "ecs_service_name must not be empty."
  }
}


# ---------------------------------------------------------------------
# ECS Task Definition Family
# ---------------------------------------------------------------------
#
# Terraform-managed ECS task definition family.
#
# ---------------------------------------------------------------------

variable "ecs_task_family" {
  description = "Amazon ECS task definition family name for the Terraform-managed Charlie Cafe application."

  type    = string
  default = "CharlieCafe-TF"

  validation {
    condition     = length(trimspace(var.ecs_task_family)) > 0
    error_message = "ecs_task_family must not be empty."
  }
}


# ---------------------------------------------------------------------
# Container Port
# ---------------------------------------------------------------------
#
# Port exposed by the Charlie Cafe Docker container.
#
# Default:
#   80
#
# ---------------------------------------------------------------------

variable "container_port" {
  description = "Port exposed by the Terraform-managed Charlie Cafe Docker container."

  type    = number
  default = 80

  validation {
    condition = (
      var.container_port >= 1 &&
      var.container_port <= 65535
    )

    error_message = "container_port must be between 1 and 65535."
  }
}


# ---------------------------------------------------------------------
# ECS Task CPU
# ---------------------------------------------------------------------
#
# Fargate CPU units.
#
# Default:
#   256
#
# 256 CPU units = 0.25 vCPU.
#
# ---------------------------------------------------------------------

variable "task_cpu" {
  description = "ECS Fargate task CPU units for the Terraform-managed service."

  type    = string
  default = "256"

  validation {
    condition = contains(
      ["256", "512", "1024", "2048", "4096", "8192", "16384"],
      var.task_cpu
    )

    error_message = "task_cpu must be a supported ECS Fargate CPU value."
  }
}


# ---------------------------------------------------------------------
# ECS Task Memory
# ---------------------------------------------------------------------
#
# Fargate task memory in MB.
#
# Default:
#   512 MB
#
# NOTE:
#   Valid CPU/memory combinations are enforced by AWS Fargate.
#
# ---------------------------------------------------------------------

variable "task_memory" {
  description = "ECS Fargate task memory in MB for the Terraform-managed service."

  type    = string
  default = "512"

  validation {
    condition = contains(
      [
        "512",
        "1024",
        "2048",
        "3072",
        "4096",
        "5120",
        "6144",
        "7168",
        "8192",
        "9216",
        "10240",
        "11264",
        "12288",
        "13312",
        "14336",
        "15360",
        "16384",
        "17408",
        "18432",
        "19456",
        "20480",
        "21504",
        "22528",
        "23552",
        "24576",
        "25600",
        "26624",
        "27648",
        "28672",
        "29696",
        "30720"
      ],
      var.task_memory
    )

    error_message = "task_memory must be a supported ECS Fargate memory value."
  }
}


# ---------------------------------------------------------------------
# ECS Desired Count
# ---------------------------------------------------------------------
#
# Number of ECS tasks Terraform should maintain.
#
# Default:
#   0
#
# WHY 0?
#
# Your Charlie Cafe deployment workflow previously used a pattern where
# the ECS infrastructure is created first with DesiredCount = 0 and
# the deployment workflow subsequently starts the service.
#
# This helps separate infrastructure creation from application
# deployment.
#
# ---------------------------------------------------------------------

variable "ecs_desired_count" {
  description = "Number of Terraform-managed ECS Fargate tasks to keep running."

  type    = number
  default = 0

  validation {
    condition     = var.ecs_desired_count >= 0
    error_message = "ecs_desired_count cannot be negative."
  }
}


# =====================================================================
# PRIVATE SUBNET CIDR VARIABLES
# =====================================================================
#
# These variables duplicate the private subnet CIDRs above.
#
# They may be required by ECS/CloudFormation-related resources that
# consume individual subnet CIDRs.
#
# Keep these values synchronized with:
#
#   private_subnet_cidrs
#
# ---------------------------------------------------------------------


# ---------------------------------------------------------------------
# Private Subnet 1 CIDR
# ---------------------------------------------------------------------

variable "private_subnet_1_cidr" {
  description = "CIDR block of Terraform private subnet 1."

  type    = string
  default = "10.0.2.0/24"

  validation {
    condition     = can(cidrnetmask(var.private_subnet_1_cidr))
    error_message = "private_subnet_1_cidr must be a valid IPv4 CIDR block."
  }
}


# ---------------------------------------------------------------------
# Private Subnet 2 CIDR
# ---------------------------------------------------------------------

variable "private_subnet_2_cidr" {
  description = "CIDR block of Terraform private subnet 2."

  type    = string
  default = "10.0.3.0/24"

  validation {
    condition     = can(cidrnetmask(var.private_subnet_2_cidr))
    error_message = "private_subnet_2_cidr must be a valid IPv4 CIDR block."
  }
}


# =====================================================================
# TERRAFORM NAMING STANDARD
# =====================================================================
#
# All Terraform-managed AWS resources should follow this convention
# wherever the AWS service supports a configurable resource name:
#
#   CharlieCafe-TF-<Resource>
#
# Examples:
#
#   VPC:
#     CharlieCafe-TF-VPC
#
#   Internet Gateway:
#     CharlieCafe-TF-InternetGateway
#
#   Public Subnet:
#     CharlieCafe-TF-PublicSubnet-1
#
#   Private Subnet:
#     CharlieCafe-TF-PrivateSubnet-1
#
#   Route Table:
#     CharlieCafe-TF-PublicRouteTable
#
#   Security Group:
#     CharlieCafe-TF-WebSecurityGroup
#
#   Load Balancer:
#     CharlieCafe-TF-ALB
#
#   Target Group:
#     CharlieCafe-TF-TargetGroup
#
#   ECS Cluster:
#     CharlieCafe-TF-Cluster
#
#   ECS Service:
#     CharlieCafe-TF-Service
#
#   IAM Role:
#     CharlieCafe-TF-<RoleName>
#
#   IAM Policy:
#     CharlieCafe-TF-<PolicyName>
#
#   S3:
#     charlie-cafe-tf-<unique-suffix>
#
#   ECR:
#     charlie-cafe-tf
#
# NOTE:
#
# AWS services have different naming restrictions. For example:
#
#   - S3 bucket names must be lowercase.
#   - ECR repository names must be lowercase.
#   - Some IAM names have length restrictions.
#   - Some AWS-generated identifiers cannot be directly controlled.
#
# Therefore, the exact "TF" pattern will be adapted to each AWS
# service in the remaining Terraform files.
#
# =====================================================================


# =====================================================================
# END OF VARIABLES
# =====================================================================
#
# IMPORTANT DEPLOYMENT NOTES
#
# Required deployment-specific values:
#
#   ami_id
#   key_pair_name
#   template_bucket_name
#
# These variables intentionally avoid hard-coded AWS-specific values.
#
# Recommended GitHub Actions environment variables:
#
#   TF_VAR_ami_id
#   TF_VAR_key_pair_name
#   TF_VAR_template_bucket_name
#
# Example:
#
#   env:
#     TF_VAR_ami_id: ${{ secrets.TF_VAR_AMI_ID }}
#     TF_VAR_key_pair_name: ${{ secrets.TF_VAR_KEY_PAIR_NAME }}
#     TF_VAR_template_bucket_name: ${{ secrets.TF_VAR_TEMPLATE_BUCKET_NAME }}
#
# NEVER put AWS_SECRET_ACCESS_KEY, database passwords, or other secrets
# directly into this file.
#
# =====================================================================
