terraform {
  # -------------------------------------------------------
  # Terraform version
  # -------------------------------------------------------
  # The lab uses modern Terraform syntax and AWS provider
  # resources.
  # -------------------------------------------------------

  required_version = ">= 1.6.0"

  # -------------------------------------------------------
  # Required Providers
  # -------------------------------------------------------

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}