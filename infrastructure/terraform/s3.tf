# =======================================================
# S3 BUCKET
# =======================================================
#
# CharlieCafe Terraform Lab
#
# CloudFormation equivalent:
#
# AWS::S3::Bucket
#
# Configuration:
#
# - Versioning enabled
# - CharlieCafe-TF naming
#
# =======================================================


# =======================================================
# S3 BUCKET
# =======================================================

resource "aws_s3_bucket" "lab" {

  # -----------------------------------------------------
  # Bucket name
  # -----------------------------------------------------
  #
  # The actual S3 bucket name is supplied through:
  #
  #   var.s3_bucket_name
  #
  # If var.s3_bucket_name is empty, Terraform will allow
  # AWS to generate a bucket name.
  #
  # Recommended naming:
  #
  #   charlie-cafe-tf-<unique-suffix>
  #
  # S3 bucket names must be globally unique.
  # -----------------------------------------------------

  bucket = var.s3_bucket_name != "" ? var.s3_bucket_name : null

  tags = {
    Name    = "CharlieCafe-TF-S3-Bucket"
    Project = "CharlieCafe-TF-Lab"
  }
}


# =======================================================
# S3 VERSIONING
# =======================================================
#
# CloudFormation:
#
# VersioningConfiguration:
#   Status: Enabled
#
# =======================================================

resource "aws_s3_bucket_versioning" "lab" {

  bucket = aws_s3_bucket.lab.id

  versioning_configuration {
    status = "Enabled"
  }
}


# =======================================================
# END OF s3.tf
# =======================================================