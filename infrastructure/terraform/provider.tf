# =======================================================

# CHARLIE CAFE - TERRAFORM DEVOPS LAB

# AWS PROVIDER CONFIGURATION

# =======================================================

#

# File:

# provider.tf

#

# Purpose:

# Configures the AWS provider used by Terraform for the

# CharlieCafe Terraform DevOps Lab.

#

# Terraform resource naming convention:

#

# Project:

# CharlieCafe-TF-Lab

#

# Application:

# CharlieCafe-TF

#

# ECR repository:

# charlie-cafe-tf

#

# ECS cluster:

# CharlieCafe-TF-Cluster

#

# ECS service:

# CharlieCafe-TF-Service

#

# ECS task definition family:

# CharlieCafe-TF

#

# Database:

# tflabdb

#

# IMPORTANT:

#

# These naming conventions are intentionally different from

# the existing CloudFormation implementation of the Charlie

# Cafe lab.

#

# This helps prevent resource-name conflicts when both the

# Terraform and CloudFormation versions exist in the same

# AWS account and region.

#

# =======================================================

#

# CLOUDFORMATION EQUIVALENT

#

# CloudFormation:

#

# AWS::Region

#

# Terraform:

#

# var.aws_region

#

# Terraform obtains AWS credentials using the standard

# AWS credential provider chain.

#

# Supported authentication methods include:

#

# - AWS CLI configuration

# - Environment variables

# - IAM roles

# - GitHub Actions credentials

# - GitHub Actions OIDC

#

# DO NOT hard-code:

#

# - AWS access keys

# - AWS secret access keys

# - Session tokens

# - Database passwords

#

# =======================================================

#

# PROVIDER CONFIGURATION

# =======================================================

provider "aws" {

# -----------------------------------------------------

# AWS REGION

# -----------------------------------------------------

#

# The deployment region is controlled through the

# Terraform variable:

#

# aws_region

#

# Default:

#

# us-east-1

#

# This keeps the provider configuration flexible and

# allows GitHub Actions or another deployment system

# to override the region when required.

#

# -----------------------------------------------------

region = var.aws_region

# -----------------------------------------------------

# DEFAULT RESOURCE TAGS

# -----------------------------------------------------

#

# Terraform automatically applies these tags to

# supported AWS resources.

#

# This provides consistent identification of resources

# belonging to the CharlieCafe Terraform lab.

#

# Example:

#

# Project     = CharlieCafe-TF-Lab

# Environment = tf-lab

# ManagedBy   = Terraform

#

# These tags are especially useful when the same AWS

# account contains both:

#

# - CloudFormation resources

# - Terraform resources

#

# -----------------------------------------------------

default_tags {


tags = {

  # ---------------------------------------------------
  # Terraform project identifier
  # ---------------------------------------------------

  Project = var.project_name


  # ---------------------------------------------------
  # Terraform environment identifier
  # ---------------------------------------------------

  Environment = var.environment


  # ---------------------------------------------------
  # Infrastructure management tool
  # ---------------------------------------------------

  ManagedBy = "Terraform"
}


}
}

# =======================================================

# END OF provider.tf

# =======================================================

#

# Naming separation:

#

# CloudFormation:

# Existing CloudFormation resource names

#

# Terraform:

# CharlieCafe-TF-Lab

# CharlieCafe-TF

# charlie-cafe-tf

# CharlieCafe-TF-Cluster

# CharlieCafe-TF-Service

# tflabdb

#

# This separation helps prevent accidental naming conflicts

# between the two infrastructure implementations.

#

# =======================================================
