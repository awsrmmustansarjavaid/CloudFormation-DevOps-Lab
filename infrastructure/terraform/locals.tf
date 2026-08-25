# =======================================================
# TERRAFORM LOCALS
# =======================================================

locals {

  # -----------------------------------------------------
  # Common resource naming
  # -----------------------------------------------------

  name_prefix = "Lab"

  # -----------------------------------------------------
  # Common tags
  # -----------------------------------------------------

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # -----------------------------------------------------
  # Public subnet names
  # -----------------------------------------------------

  public_subnet_names = [
    "Public-Subnet-1",
    "Public-Subnet-2"
  ]

  # -----------------------------------------------------
  # Private subnet names
  # -----------------------------------------------------

  private_subnet_names = [
    "Private-Subnet-1",
    "Private-Subnet-2"
  ]
}