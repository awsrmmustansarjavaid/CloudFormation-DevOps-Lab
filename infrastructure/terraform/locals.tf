# =======================================================
# CHARLIE CAFE - TERRAFORM LOCALS
# =======================================================
#
# File:
#   locals.tf
#
# Purpose:
#   Defines reusable local values used throughout the
#   Charlie Cafe Terraform infrastructure.
#
# IMPORTANT:
#
#   This Terraform lab exists alongside the existing
#   CloudFormation version of the Charlie Cafe lab.
#
#   Therefore Terraform-managed AWS resources use the
#   "CharlieCafe-TF" naming pattern to clearly separate
#   them from CloudFormation-managed resources.
#
# Naming convention:
#
#   CloudFormation:
#     CharlieCafe
#     AWS-CloudFormation-TF-Lab
#
#   Terraform:
#     CharlieCafe-TF
#     CharlieCafe-TF-Lab
#
# Examples:
#
#   VPC:
#     CharlieCafe-TF-Lab-VPC
#
#   Subnet:
#     CharlieCafe-TF-Public-Subnet-1
#
#   Security Group:
#     CharlieCafe-TF-ALB-SG
#
#   ECS Cluster:
#     CharlieCafe-TF-Cluster
#
#   ECS Service:
#     CharlieCafe-TF-Service
#
#   ECR:
#     charlie-cafe-tf
#
# =======================================================


locals {

  # -----------------------------------------------------
  # Common Terraform resource naming prefix
  # -----------------------------------------------------
  #
  # This prefix is used by Terraform-managed resources
  # where a resource name is constructed from local values.
  #
  # The "TF" identifier makes it immediately clear that
  # the resource belongs to the Terraform implementation
  # of the Charlie Cafe lab.
  #
  # CloudFormation resources use their own naming pattern,
  # so this prevents accidental naming conflicts.
  #
  # Example:
  #
  #   CharlieCafe-TF-VPC
  #   CharlieCafe-TF-ALB
  #   CharlieCafe-TF-ALB-SG
  #
  # -----------------------------------------------------

  name_prefix = "CharlieCafe-TF"


  # -----------------------------------------------------
  # Common tags
  # -----------------------------------------------------
  #
  # These tags are intended to be reused across Terraform
  # resources.
  #
  # ManagedBy = Terraform allows AWS resources to be
  # identified as Terraform-managed when viewing them
  # through the AWS Console, CLI, or billing reports.
  #
  # -----------------------------------------------------

  common_tags = {

    # Project name comes from variables.tf.
    #
    # Default:
    #   CharlieCafe-TF-Lab
    #
    Project = var.project_name

    # Environment identifier.
    #
    # Default:
    #   tf-lab
    #
    Environment = var.environment

    # Identifies Terraform as the infrastructure manager.
    ManagedBy = "Terraform"
  }


  # -----------------------------------------------------
  # Public subnet names
  # -----------------------------------------------------
  #
  # Public subnets are located in the public portion of
  # the Charlie Cafe Terraform VPC.
  #
  # The CharlieCafe-TF prefix prevents these subnet names
  # from conflicting with the equivalent CloudFormation
  # resources.
  #
  # Result:
  #
  #   CharlieCafe-TF-Public-Subnet-1
  #   CharlieCafe-TF-Public-Subnet-2
  #
  # -----------------------------------------------------

  public_subnet_names = [

    "CharlieCafe-TF-Public-Subnet-1",

    "CharlieCafe-TF-Public-Subnet-2"
  ]


  # -----------------------------------------------------
  # Private subnet names
  # -----------------------------------------------------
  #
  # Private subnets are used by internal resources such as
  # ECS Fargate tasks and RDS.
  #
  # The CharlieCafe-TF prefix keeps these resources
  # separate from the CloudFormation version.
  #
  # Result:
  #
  #   CharlieCafe-TF-Private-Subnet-1
  #   CharlieCafe-TF-Private-Subnet-2
  #
  # -----------------------------------------------------

  private_subnet_names = [

    "CharlieCafe-TF-Private-Subnet-1",

    "CharlieCafe-TF-Private-Subnet-2"
  ]
}


# =======================================================
# END OF locals.tf
# =======================================================
#
# Terraform naming strategy:
#
#   Project:
#     CharlieCafe-TF-Lab
#
#   Application:
#     CharlieCafe-TF
#
#   ECR:
#     charlie-cafe-tf
#
#   ECS Cluster:
#     CharlieCafe-TF-Cluster
#
#   ECS Service:
#     CharlieCafe-TF-Service
#
#   ECS Task Family:
#     CharlieCafe-TF
#
#   Database:
#     tflabdb
#
#   Resource prefix:
#     CharlieCafe-TF
#
# This naming strategy keeps the Terraform infrastructure
# clearly separated from the existing CloudFormation
# infrastructure in the same AWS account.
#
# =======================================================

