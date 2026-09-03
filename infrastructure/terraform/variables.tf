# =====================================================================
# CHARLIE CAFE - AWS TERRAFORM DEVOPS LAB
# TERRAFORM INPUT VARIABLES
# =====================================================================
#
# File:
#   infrastructure/terraform/variables.tf
#
# Purpose:
#   Defines configurable input variables used by the Terraform
#   infrastructure for the Charlie Cafe AWS DevOps Lab.
#
# =====================================================================
#
# IMPORTANT RESOURCE NAMING CONVENTION
# =====================================================================
#
# Terraform infrastructure exists alongside a separate CloudFormation
# implementation of the Charlie Cafe lab.
#
# Terraform-created AWS resources should therefore use:
#
#   TF
#
# as their unique naming identifier wherever AWS allows custom names.
#
# Examples:
#
#   CharlieCafe-TF-VPC
#   CharlieCafe-TF-PublicSubnet-1
#   CharlieCafe-TF-PrivateSubnet-1
#   CharlieCafe-TF-ALB
#   CharlieCafe-TF-Cluster
#   CharlieCafe-TF-Service
#
# Terraform internal resource addresses do not need to contain "TF".
#
# =====================================================================
#
# SECURITY:
#
# Do NOT store:
#
#   - AWS access keys
#   - AWS secret keys
#   - Database passwords
#   - API secrets
#   - Application credentials
#
# in this file.
#
# Sensitive information should be supplied through appropriate secure
# mechanisms such as:
#
#   - AWS Secrets Manager
#   - GitHub Actions Secrets
#   - Environment Variables
#   - Secure Terraform variable injection
#
# =====================================================================


# =====================================================================
# AWS PROVIDER / GENERAL PROJECT VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# AWS REGION
# ---------------------------------------------------------------------

variable "aws_region" {

  description = "AWS region where the Terraform lab infrastructure will be deployed."

  type    = string
  default = "us-east-1"

  validation {

    condition = length(
      trimspace(var.aws_region)
    ) > 0

    error_message = "AWS region must not be empty."
  }
}


# ---------------------------------------------------------------------
# PROJECT NAME
# ---------------------------------------------------------------------

variable "project_name" {

  description = "Name of the AWS Terraform project."

  type    = string
  default = "CharlieCafe-TF-Lab"

  validation {

    condition = length(
      trimspace(var.project_name)
    ) > 0

    error_message = "Project name must not be empty."
  }
}


# ---------------------------------------------------------------------
# ENVIRONMENT
# ---------------------------------------------------------------------

variable "environment" {

  description = "Environment name used for Terraform resource naming and tagging."

  type    = string
  default = "tf-lab"

  validation {

    condition = contains(
      [
        "lab",
        "dev",
        "development",
        "staging",
        "prod",
        "production",
        "tf-lab"
      ],
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

variable "vpc_cidr" {

  description = "CIDR block for the Charlie Cafe Terraform VPC."

  type    = string
  default = "10.0.0.0/16"

  validation {

    condition = can(
      cidrnetmask(var.vpc_cidr)
    )

    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}


# ---------------------------------------------------------------------
# AVAILABILITY ZONES
# ---------------------------------------------------------------------

variable "availability_zones" {

  description = "Two Availability Zones used by the Charlie Cafe Terraform infrastructure."

  type = list(string)

  default = [
    "us-east-1a",
    "us-east-1b"
  ]

  validation {

    condition = length(
      var.availability_zones
    ) == 2

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
# PUBLIC SUBNET CIDRS
# ---------------------------------------------------------------------

variable "public_subnet_cidrs" {

  description = "CIDR blocks for the two Terraform public subnets."

  type = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.4.0/24"
  ]

  validation {

    condition = length(
      var.public_subnet_cidrs
    ) == 2

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
# PRIVATE SUBNET CIDRS
# ---------------------------------------------------------------------

variable "private_subnet_cidrs" {

  description = "CIDR blocks for the two Terraform private subnets."

  type = list(string)

  default = [
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  validation {

    condition = length(
      var.private_subnet_cidrs
    ) == 2

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
# EC2 INSTANCE TYPE
# ---------------------------------------------------------------------

variable "instance_type" {

  description = "EC2 instance type used by the Terraform-managed web server."

  type    = string
  default = "t3.micro"

  validation {

    condition = length(
      trimspace(var.instance_type)
    ) > 0

    error_message = "EC2 instance type must not be empty."
  }
}


# ---------------------------------------------------------------------
# EC2 KEY PAIR
# ---------------------------------------------------------------------

variable "key_pair_name" {

  description = "Existing EC2 Key Pair name used for SSH access by the Terraform-managed server."

  type    = string
  default = ""

  validation {

    condition = length(
      trimspace(var.key_pair_name)
    ) > 0

    error_message = "key_pair_name must contain the name of an existing EC2 Key Pair."
  }
}


# ---------------------------------------------------------------------
# EC2 USERDATA SCRIPT URL
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
# S3 APPLICATION BUCKET NAME
# ---------------------------------------------------------------------
#
# This variable is used by the Terraform S3 configuration.
#
# IMPORTANT:
#
# CloudFront does NOT need a separate "bucket_name" variable.
#
# CloudFront obtains the actual bucket information directly from:
#
#   aws_s3_bucket.website
#
# This prevents the CloudFront configuration from becoming
# inconsistent with the actual S3 bucket.
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
        can(
          regex(
            "^[a-z0-9][a-z0-9.-]*[a-z0-9]$",
            var.s3_bucket_name
          )
        )
      )
    )

    error_message = "s3_bucket_name must be empty or a valid S3 bucket name between 3 and 63 characters using lowercase letters, numbers, dots, and hyphens."
  }
}


# =====================================================================
# CLOUDFRONT VARIABLES
# =====================================================================
#
# These variables control configurable CloudFront behavior.
#
# The actual S3 bucket name, ARN and regional endpoint are NOT supplied
# as variables.
#
# They are obtained directly from:
#
#   aws_s3_bucket.website
#
# This is intentional.
#
# =====================================================================


# ---------------------------------------------------------------------
# CLOUDFRONT PRICE CLASS
# ---------------------------------------------------------------------

variable "cloudfront_price_class" {

  description = "CloudFront price class for the Charlie Cafe website distribution."

  type    = string
  default = "PriceClass_100"

  validation {

    condition = contains(
      [
        "PriceClass_100",
        "PriceClass_200",
        "PriceClass_All"
      ],
      var.cloudfront_price_class
    )

    error_message = "cloudfront_price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}


# ---------------------------------------------------------------------
# CLOUDFRONT DEFAULT ROOT OBJECT
# ---------------------------------------------------------------------
#
# Matches the CloudFormation configuration:
#
#   DefaultRootObject: index.php
#
# ---------------------------------------------------------------------

variable "cloudfront_default_root_object" {

  description = "Default root object served by the CloudFront distribution."

  type    = string
  default = "index.php"

  validation {

    condition = length(
      trimspace(var.cloudfront_default_root_object)
    ) > 0

    error_message = "cloudfront_default_root_object must not be empty."
  }
}


# ---------------------------------------------------------------------
# CLOUDFRONT COMMENT
# ---------------------------------------------------------------------

variable "cloudfront_comment" {

  description = "Description/comment for the Charlie Cafe CloudFront distribution."

  type    = string
  default = "CloudFront distribution for S3 website"
}


# ---------------------------------------------------------------------
# CLOUDFRONT IPV6
# ---------------------------------------------------------------------
#
# Matches:
#
#   CloudFormation:
#     IPV6Enabled: true
#
# ---------------------------------------------------------------------

variable "cloudfront_ipv6_enabled" {

  description = "Whether IPv6 should be enabled for the CloudFront distribution."

  type    = bool
  default = true
}


# ---------------------------------------------------------------------
# CLOUDFRONT HTTP VERSION
# ---------------------------------------------------------------------
#
# Matches:
#
#   CloudFormation:
#     HttpVersion: http2and3
#
# ---------------------------------------------------------------------

variable "cloudfront_http_version" {

  description = "HTTP version supported by the CloudFront distribution."

  type    = string
  default = "http2and3"

  validation {

    condition = contains(
      [
        "http1.1",
        "http2",
        "http3",
        "http2and3"
      ],
      var.cloudfront_http_version
    )

    error_message = "cloudfront_http_version must be http1.1, http2, http3, or http2and3."
  }
}


# ---------------------------------------------------------------------
# CLOUDFRONT VIEWER PROTOCOL POLICY
# ---------------------------------------------------------------------
#
# Matches:
#
#   CloudFormation:
#     ViewerProtocolPolicy: redirect-to-https
#
# ---------------------------------------------------------------------

variable "cloudfront_viewer_protocol_policy" {

  description = "Viewer protocol policy for the CloudFront distribution."

  type    = string
  default = "redirect-to-https"

  validation {

    condition = contains(
      [
        "allow-all",
        "redirect-to-https",
        "https-only"
      ],
      var.cloudfront_viewer_protocol_policy
    )

    error_message = "cloudfront_viewer_protocol_policy must be allow-all, redirect-to-https, or https-only."
  }
}


# ---------------------------------------------------------------------
# CLOUDFRONT COMPRESSION
# ---------------------------------------------------------------------
#
# Matches:
#
#   CloudFormation:
#     Compress: true
#
# ---------------------------------------------------------------------

variable "cloudfront_compress" {

  description = "Whether CloudFront should automatically compress supported objects."

  type    = bool
  default = true
}


# ---------------------------------------------------------------------
# CLOUDFRONT GEOGRAPHIC RESTRICTION
# ---------------------------------------------------------------------
#
# Matches:
#
#   CloudFormation:
#     RestrictionType: none
#
# ---------------------------------------------------------------------

variable "cloudfront_geo_restriction_type" {

  description = "Geographic restriction type for the CloudFront distribution."

  type    = string
  default = "none"

  validation {

    condition = contains(
      [
        "none",
        "whitelist",
        "blacklist"
      ],
      var.cloudfront_geo_restriction_type
    )

    error_message = "cloudfront_geo_restriction_type must be none, whitelist, or blacklist."
  }
}


# =====================================================================
# RDS / MYSQL VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# DATABASE NAME
# ---------------------------------------------------------------------

variable "db_name" {

  description = "Initial MySQL database name used by the Terraform-managed RDS instance."

  type    = string
  default = "tflabdb"

  validation {

    condition = can(
      regex(
        "^[A-Za-z][A-Za-z0-9_]*$",
        var.db_name
      )
    )

    error_message = "db_name must start with a letter and contain only letters, numbers, and underscores."
  }
}


# ---------------------------------------------------------------------
# RDS MASTER USERNAME
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
# RDS INSTANCE CLASS
# ---------------------------------------------------------------------

variable "db_instance_class" {

  description = "RDS MySQL DB instance class for the Terraform-managed database."

  type    = string
  default = "db.t3.micro"

  validation {

    condition = length(
      trimspace(var.db_instance_class)
    ) > 0

    error_message = "db_instance_class must not be empty."
  }
}


# ---------------------------------------------------------------------
# RDS ENGINE VERSION
# ---------------------------------------------------------------------

variable "db_engine_version" {

  description = "MySQL engine version for the Terraform-managed RDS database."

  type    = string
  default = "8.0"

  validation {

    condition = length(
      trimspace(var.db_engine_version)
    ) > 0

    error_message = "db_engine_version must not be empty."
  }
}


# ---------------------------------------------------------------------
# RDS ALLOCATED STORAGE
# ---------------------------------------------------------------------

variable "db_allocated_storage" {

  description = "Initial RDS allocated storage in GB for the Terraform-managed database."

  type    = number
  default = 20

  validation {

    condition = var.db_allocated_storage >= 20

    error_message = "RDS allocated storage must be at least 20 GB."
  }
}


# ---------------------------------------------------------------------
# RDS BACKUP RETENTION
# ---------------------------------------------------------------------

variable "db_backup_retention_period" {

  description = "Number of days to retain automated RDS backups for the Terraform-managed database."

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
# RDS STORAGE ENCRYPTION
# ---------------------------------------------------------------------

variable "db_storage_encrypted" {

  description = "Whether storage encryption should be enabled for the Terraform-managed RDS database."

  type    = bool
  default = false
}


# ---------------------------------------------------------------------
# RDS DELETION PROTECTION
# ---------------------------------------------------------------------

variable "db_deletion_protection" {

  description = "Whether RDS deletion protection should be enabled for the Terraform-managed database."

  type    = bool
  default = false
}


# =====================================================================
# CLOUDFORMATION TEMPLATE S3 BUCKET
# =====================================================================

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
        can(
          regex(
            "^[a-z0-9][a-z0-9.-]*[a-z0-9]$",
            var.template_bucket_name
          )
        )
      )
    )

    error_message = "template_bucket_name must be empty or a valid globally unique S3 bucket name between 3 and 63 characters."
  }
}


# =====================================================================
# ECS / ECR VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# APPLICATION NAME
# ---------------------------------------------------------------------

variable "application_name" {

  description = "Application name used for Terraform-managed ECS, ECR, ALB and related AWS resources."

  type    = string
  default = "CharlieCafe-TF"

  validation {

    condition = can(
      regex(
        "^[A-Za-z][A-Za-z0-9-]*$",
        var.application_name
      )
    )

    error_message = "application_name must start with a letter and contain only letters, numbers, and hyphens."
  }
}


# ---------------------------------------------------------------------
# ECR REPOSITORY NAME
# ---------------------------------------------------------------------

variable "ecr_repository_name" {

  description = "Amazon ECR repository name for the Terraform-managed Charlie Cafe Docker image."

  type    = string
  default = "charlie-cafe-tf"

  validation {

    condition = can(
      regex(
        "^[a-z0-9]+(?:[._/-][a-z0-9]+)*$",
        var.ecr_repository_name
      )
    )

    error_message = "ecr_repository_name contains invalid characters."
  }
}


# ---------------------------------------------------------------------
# ECS CLUSTER NAME
# ---------------------------------------------------------------------

variable "ecs_cluster_name" {

  description = "Amazon ECS cluster name for the Terraform-managed Charlie Cafe infrastructure."

  type    = string
  default = "CharlieCafe-TF-Cluster"

  validation {

    condition = length(
      trimspace(var.ecs_cluster_name)
    ) > 0

    error_message = "ecs_cluster_name must not be empty."
  }
}


# ---------------------------------------------------------------------
# ECS SERVICE NAME
# ---------------------------------------------------------------------

variable "ecs_service_name" {

  description = "Amazon ECS service name for the Terraform-managed Charlie Cafe infrastructure."

  type    = string
  default = "CharlieCafe-TF-Service"

  validation {

    condition = length(
      trimspace(var.ecs_service_name)
    ) > 0

    error_message = "ecs_service_name must not be empty."
  }
}


# ---------------------------------------------------------------------
# ECS TASK DEFINITION FAMILY
# ---------------------------------------------------------------------

variable "ecs_task_family" {

  description = "Amazon ECS task definition family name for the Terraform-managed Charlie Cafe application."

  type    = string
  default = "CharlieCafe-TF"

  validation {

    condition = length(
      trimspace(var.ecs_task_family)
    ) > 0

    error_message = "ecs_task_family must not be empty."
  }
}


# ---------------------------------------------------------------------
# CONTAINER PORT
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
# ECS TASK CPU
# ---------------------------------------------------------------------

variable "task_cpu" {

  description = "ECS Fargate task CPU units for the Terraform-managed service."

  type    = string
  default = "256"

  validation {

    condition = contains(
      [
        "256",
        "512",
        "1024",
        "2048",
        "4096",
        "8192",
        "16384"
      ],
      var.task_cpu
    )

    error_message = "task_cpu must be a supported ECS Fargate CPU value."
  }
}


# ---------------------------------------------------------------------
# ECS TASK MEMORY
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
# ECS DESIRED COUNT
# ---------------------------------------------------------------------

variable "ecs_desired_count" {

  description = "Number of Terraform-managed ECS Fargate tasks to keep running."

  type    = number
  default = 1

  validation {

    condition = var.ecs_desired_count >= 1

    error_message = "ecs_desired_count must be at least 1."
  }
}


# =====================================================================
# PRIVATE SUBNET CIDR VARIABLES
# =====================================================================


# ---------------------------------------------------------------------
# PRIVATE SUBNET 1 CIDR
# ---------------------------------------------------------------------

variable "private_subnet_1_cidr" {

  description = "CIDR block of Terraform private subnet 1."

  type    = string
  default = "10.0.2.0/24"

  validation {

    condition = can(
      cidrnetmask(var.private_subnet_1_cidr)
    )

    error_message = "private_subnet_1_cidr must be a valid IPv4 CIDR block."
  }
}


# ---------------------------------------------------------------------
# PRIVATE SUBNET 2 CIDR
# ---------------------------------------------------------------------

variable "private_subnet_2_cidr" {

  description = "CIDR block of Terraform private subnet 2."

  type    = string
  default = "10.0.3.0/24"

  validation {

    condition = can(
      cidrnetmask(var.private_subnet_2_cidr)
    )

    error_message = "private_subnet_2_cidr must be a valid IPv4 CIDR block."
  }
}


# =====================================================================
# TERRAFORM NAMING STANDARD
# =====================================================================
#
# Wherever AWS supports configurable names, Terraform resources should
# follow:
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
#
# S3 and ECR have different naming restrictions:
#
#   S3:
#     lowercase only
#
#   ECR:
#     lowercase repository names
#
# =====================================================================


# =====================================================================
# END OF variables.tf
# =====================================================================