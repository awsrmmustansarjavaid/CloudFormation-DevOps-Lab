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
#        | HTTPS
#        v
#   CloudFront Distribution
#        |
#        | Signed SigV4 Request
#        v
#   S3 Bucket
#
# Security:
#
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
#   It is NOT an IAM user policy.
#
#   Terraform creates and manages this policy directly on the S3
#   bucket.
#
# =====================================================================


# =====================================================================
# IAM POLICY DOCUMENT
# =====================================================================
#
# Generates the JSON policy document that will be attached to the
# Terraform-managed S3 bucket.
#
# IMPORTANT:
#
#   aws_iam_policy_document
#
# does NOT create an AWS IAM managed policy.
#
# It only generates policy JSON that is consumed by:
#
#   aws_s3_bucket_policy.website
#
# =====================================================================

data "aws_iam_policy_document" "website_bucket_policy" {


  # ===================================================================
  # CLOUDFRONT READ-ONLY ACCESS
  # ===================================================================
  #
  # Allows CloudFront to retrieve website objects from the S3 bucket.
  #
  # CloudFront uses:
  #
  #   s3:GetObject
  #
  # to retrieve files such as:
  #
  #   index.html
  #   CSS files
  #   JavaScript files
  #   images
  #   fonts
  #   other static website assets
  #
  # ===================================================================

  statement {

    # -----------------------------------------------------------------
    # Policy Statement ID
    # -----------------------------------------------------------------
    #
    # Unique identifier for this statement.
    #
    sid = "AllowCloudFrontServicePrincipalReadOnly"


    # -----------------------------------------------------------------
    # Effect
    # -----------------------------------------------------------------
    #
    # Allows the specified action.
    #
    effect = "Allow"


    # -----------------------------------------------------------------
    # CloudFront Service Principal
    # -----------------------------------------------------------------
    #
    # Identifies Amazon CloudFront as the AWS service that is allowed
    # to access the S3 objects.
    #
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
    # This matches the CloudFormation policy:
    #
    #   Action:
    #     - s3:GetObject
    #
    actions = [
      "s3:GetObject"
    ]


    # -----------------------------------------------------------------
    # S3 Object Resources
    # -----------------------------------------------------------------
    #
    # The "/*" means all objects inside the S3 bucket.
    #
    # Example:
    #
    #   bucket/index.html
    #   bucket/css/style.css
    #   bucket/js/app.js
    #
    # are covered by this resource.
    #
    resources = [
      "${aws_s3_bucket.website.arn}/*"
    ]


    # =================================================================
    # RESTRICT ACCESS TO THIS CLOUDFRONT DISTRIBUTION
    # =================================================================
    #
    # AWS:SourceArn ensures that the S3 bucket accepts requests from
    # the specific CloudFront distribution created by this Terraform
    # configuration.
    #
    # This prevents another CloudFront distribution from using this
    # bucket policy to retrieve objects.
    #
    # This matches the CloudFormation configuration:
    #
    #   AWS:SourceArn:
    #     arn:${AWS::Partition}:cloudfront::${AWS::AccountId}:
    #     distribution/${CloudFrontDistribution}
    #
    # Terraform obtains the equivalent ARN directly from:
    #
    #   aws_cloudfront_distribution.website.arn
    #
    # =================================================================

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
# Attaches the policy document above directly to the Terraform-managed
# S3 bucket.
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
  # This assumes the S3 bucket in your existing s3.tf is declared as:
  #
  #   resource "aws_s3_bucket" "website"
  #
  # If your actual resource name is different, this reference must
  # match that resource exactly.
  #
  bucket = aws_s3_bucket.website.id


  # -------------------------------------------------------------------
  # Policy JSON
  # -------------------------------------------------------------------
  #
  # Uses the IAM policy document generated above.
  #
  policy = data.aws_iam_policy_document.website_bucket_policy.json
}


# =====================================================================
# END OF S3 CLOUDFRONT BUCKET POLICY
# =====================================================================