# =======================================================
# S3 BUCKET
# =======================================================
#
# CloudFormation equivalent:
#
# AWS::S3::Bucket
#
# Configuration:
#
# - Versioning enabled
# - Name tag
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
  # If var.s3_bucket_name is empty, Terraform will allow
  # AWS to generate a bucket name.
  # -----------------------------------------------------

  bucket = var.s3_bucket_name != "" ? var.s3_bucket_name : null

  tags = {
    Name = "Lab-S3-Bucket"
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
# =======================================================

resource "aws_s3_bucket_versioning" "lab" {

  bucket = aws_s3_bucket.lab.id

  versioning_configuration {
    status = "Enabled"
  }
}