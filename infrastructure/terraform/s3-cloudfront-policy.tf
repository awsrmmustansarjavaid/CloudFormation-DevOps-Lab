# =====================================================================
# CHARLIE CAFE - S3 BUCKET POLICY FOR CLOUDFRONT
# =====================================================================
#
# File:
#   infrastructure/terraform/s3-cloudfront-policy.tf
#
# Purpose:
#   Allows the CloudFront distribution to read website objects from
#   the Terraform-managed S3 bucket.
#
# Architecture:
#
#   Internet User
#        |
#        v
#   CloudFront Distribution
#        |
#        | s3:GetObject
#        v
#   Terraform S3 Bucket
#
# Security:
#   The bucket policy allows only the CloudFront AWS service principal
#   to read objects.
#
#   The AWS:SourceArn condition restricts access to the specific
#   CloudFront distribution created by this Terraform configuration.
#
# IMPORTANT:
#
#   This is an S3 BUCKET POLICY.
#
#   It is NOT an IAM user policy and does NOT need to be created
#   manually in the AWS IAM Console.
#
#   Terraform will create and manage this policy in AWS.
#
# =====================================================================


# =====================================================================
# IAM POLICY DOCUMENT
# =====================================================================
#
# Creates the JSON policy document that will be attached to the
# Terraform-managed S3 bucket.
#
# aws_iam_policy_document does NOT create an AWS IAM policy by itself.
#
# It generates the policy JSON that is later used by:
#
#   aws_s3_bucket_policy
#
# =====================================================================

data "aws_iam_policy_document" "website_bucket_policy" {

  # -------------------------------------------------------------------
  # CloudFront Read-Only Access
  # -------------------------------------------------------------------
  #
  # Allows CloudFront to read objects from the S3 website bucket.
  #
  # CloudFront uses:
  #
  #   s3:GetObject
  #
  # to retrieve files such as:
  #
  #   index.html
  #   css files
  #   JavaScript files
  #   images
  #
  # -------------------------------------------------------------------

  statement {

    # Unique identifier for this policy statement.
    sid = "AllowCloudFrontServicePrincipalReadOnly"

    # Allow the requested action.
    effect = "Allow"


    # -----------------------------------------------------------------
    # CloudFront AWS Service Principal
    # -----------------------------------------------------------------
    #
    # Identifies CloudFront as the AWS service that is allowed to
    # access the S3 objects.
    #
    # -----------------------------------------------------------------

    principals {

      type = "Service"

      identifiers = [
        "cloudfront.amazonaws.com"
      ]
    }


    # -----------------------------------------------------------------
    # Allowed S3 Action
    # -----------------------------------------------------------------
    #
    # Allows CloudFront to retrieve objects from the bucket.
    #
    # -----------------------------------------------------------------

    actions = [
      "s3:GetObject"
    ]


    # -----------------------------------------------------------------
    # Protected S3 Objects
    # -----------------------------------------------------------------
    #
    # The "/*" means all objects inside the S3 bucket.
    #
    # IMPORTANT:
    #
    # Replace the resource reference below with the exact S3 bucket
    # resource from your existing s3.tf.
    #
    # We will confirm the correct resource name from s3.tf before
    # running Terraform.
    #
    # -----------------------------------------------------------------

    resources = [
      "${aws_s3_bucket.website.arn}/*"
    ]


    # -----------------------------------------------------------------
    # Restrict Access to This CloudFront Distribution
    # -----------------------------------------------------------------
    #
    # AWS:SourceArn ensures that the S3 bucket accepts requests only
    # from the specific CloudFront distribution created by Terraform.
    #
    # This prevents another CloudFront distribution from using this
    # bucket policy.
    #
    # -----------------------------------------------------------------

    condition {

      test = "StringEquals"

      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.website.arn
      ]
    }
  }
}


# =====================================================================
# S3 BUCKET POLICY
# =====================================================================
#
# Attaches the policy document above to the Terraform-managed S3
# bucket.
#
# This makes the policy active on the S3 bucket.
#
# =====================================================================

resource "aws_s3_bucket_policy" "website" {

  # -------------------------------------------------------------------
  # Target S3 Bucket
  # -------------------------------------------------------------------
  #
  # IMPORTANT:
  #
  # Replace this reference with the exact S3 bucket resource from
  # your existing s3.tf if the resource is not named "website".
  #
  # -------------------------------------------------------------------

  bucket = aws_s3_bucket.website.id


  # -------------------------------------------------------------------
  # Policy JSON
  # -------------------------------------------------------------------
  #
  # Uses the IAM policy document defined above.
  #
  # -------------------------------------------------------------------

  policy = data.aws_iam_policy_document.website_bucket_policy.json
}


# =====================================================================
# END OF CLOUDFRONT S3 BUCKET POLICY
# =====================================================================

