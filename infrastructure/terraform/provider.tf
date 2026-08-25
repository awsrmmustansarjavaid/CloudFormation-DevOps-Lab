# =======================================================
# AWS PROVIDER CONFIGURATION
# =======================================================
#
# CloudFormation equivalent:
#
# AWS::Region
#
# Terraform obtains AWS credentials using the standard
# AWS credential provider chain.
#
# Examples:
#
# - AWS CLI configuration
# - Environment variables
# - IAM role
# - GitHub Actions OIDC
#
# DO NOT hard-code AWS access keys or secret keys here.
# =======================================================

provider "aws" {
  region = var.aws_region

  # -----------------------------------------------------
  # Default tags
  # -----------------------------------------------------
  #
  # These tags are automatically applied to supported
  # resources created by Terraform.
  #
  # This reduces repeated tagging code.
  # -----------------------------------------------------

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}