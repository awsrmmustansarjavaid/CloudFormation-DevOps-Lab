# =========================================================
# Charlie Cafe / AWS DevOps Lab
# Terraform Infrastructure
#
# File:
#   template_bucket.tf
#
# Purpose:
#   Creates the S3 bucket used to store the CloudFormation
#   nested-stack templates.
#
# CloudFormation equivalent:
#   TemplateBucket-MainStack.yaml
#
# This bucket is separate from the application/lab S3 bucket
# defined in s3.tf.
# =========================================================


# =========================================================
# S3 BUCKET
# =========================================================
#
# This bucket replaces the CloudFormation resource:
#
#   TemplateBucket:
#     Type: AWS::S3::Bucket
#
# Its purpose is to store nested CloudFormation templates.
#
# Example objects:
#
#   templates/ec2-webserver.yaml
#   templates/aws-rds.yaml
#   templates/s3.yaml
#
# =========================================================

resource "aws_s3_bucket" "template_bucket" {

  # -------------------------------------------------------
  # Bucket name
  # -------------------------------------------------------
  #
  # We intentionally do not hard-code a bucket name here.
  #
  # AWS S3 bucket names must be globally unique.
  #
  # The actual name will be supplied through:
  #
  #   var.template_bucket_name
  #
  # Example:
  #
  #   cloudformation-devops-lab-537236558357-us-east-1
  #
  # -------------------------------------------------------

  bucket = var.template_bucket_name


  # -------------------------------------------------------
  # Resource tags
  # -------------------------------------------------------

  tags = {
    Name    = "Lab-CloudFormation-Templates"
    Purpose = "CloudFormation-Nested-Templates"
  }
}


# =========================================================
# S3 VERSIONING
# =========================================================
#
# CloudFormation equivalent:
#
#   VersioningConfiguration:
#     Status: Enabled
#
# Versioning allows previous versions of uploaded
# CloudFormation templates to be retained.
#
# This is useful for:
#
#   - Recovering accidentally overwritten templates
#   - Tracking template changes
#   - Safer lab experimentation
#
# =========================================================

resource "aws_s3_bucket_versioning" "template_bucket" {

  # -------------------------------------------------------
  # Attach versioning configuration to the bucket
  # -------------------------------------------------------

  bucket = aws_s3_bucket.template_bucket.id

  versioning_configuration {

    # Enable S3 object versioning
    status = "Enabled"
  }
}