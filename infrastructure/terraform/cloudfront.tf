# ============================================================
# CHARLIE CAFE - CLOUDFRONT + S3 ORIGIN ACCESS CONTROL
# ============================================================
#
# File:
#   infrastructure/terraform/cloudfront.tf
#
# Purpose:
#   Creates an Amazon CloudFront distribution that securely
#   delivers the Terraform-managed S3 static website.
#
# Architecture:
#
#   Internet User
#        |
#        | HTTPS
#        v
#   CloudFront Distribution
#        |
#        | Signed SigV4 request
#        v
#   CloudFront Origin Access Control (OAC)
#        |
#        | s3:GetObject
#        v
#   Private S3 Website Bucket
#
# Security:
#   - S3 bucket is accessed through CloudFront OAC.
#   - OAC uses AWS Signature Version 4.
#   - CloudFront signs every request sent to S3.
#   - S3 bucket policy restricts access to this distribution.
#
# IMPORTANT:
#   The S3 bucket policy is defined separately in:
#
#     s3-cloudfront-policy.tf
#
# ============================================================


# ============================================================
# 1. CLOUDFRONT ORIGIN ACCESS CONTROL
# ============================================================
#
# Creates an Origin Access Control (OAC) for the S3 origin.
#
# OAC is the recommended CloudFront mechanism for securely
# accessing an S3 bucket without making the bucket public.
#
# ============================================================

resource "aws_cloudfront_origin_access_control" "website" {

  # ----------------------------------------------------------
  # OAC Name
  # ----------------------------------------------------------
  #
  # Uses the S3 bucket name so the OAC can be easily identified
  # in the AWS Management Console.
  #
  name = "${aws_s3_bucket.lab.id}-oac"


  # ----------------------------------------------------------
  # OAC Description
  # ----------------------------------------------------------
  #
  # Explains the purpose of this Origin Access Control.
  #
  description = "CloudFront OAC for S3 website"


  # ----------------------------------------------------------
  # Origin Type
  # ----------------------------------------------------------
  #
  # The protected origin is Amazon S3.
  #
  origin_access_control_origin_type = "s3"


  # ----------------------------------------------------------
  # Signing Behavior
  # ----------------------------------------------------------
  #
  # CloudFront signs every request sent to the S3 origin.
  #
  # This corresponds to:
  #
  #   SigningBehavior: always
  #
  signing_behavior = "always"


  # ----------------------------------------------------------
  # Signing Protocol
  # ----------------------------------------------------------
  #
  # CloudFront uses AWS Signature Version 4 (SigV4).
  #
  # This corresponds to:
  #
  #   SigningProtocol: sigv4
  #
  signing_protocol = "sigv4"
}


# ============================================================
# 2. CLOUDFRONT DISTRIBUTION
# ============================================================
#
# Creates the CloudFront distribution that delivers the
# static website stored in the S3 bucket.
#
# ============================================================

resource "aws_cloudfront_distribution" "website" {

  # ----------------------------------------------------------
  # Enable Distribution
  # ----------------------------------------------------------
  #
  # Enables the CloudFront distribution.
  #
  enabled = true


  # ----------------------------------------------------------
  # Distribution Comment
  # ----------------------------------------------------------
  #
  # Description displayed in the CloudFront console.
  #
  comment = "Charlie Cafe S3 Website"


  # ----------------------------------------------------------
  # Default Root Object
  # ----------------------------------------------------------
  #
  # When a user visits the CloudFront root URL, CloudFront
  # serves index.html.
  #
  default_root_object = "index.html"


  # ----------------------------------------------------------
  # IPv6
  # ----------------------------------------------------------
  #
  # Enables IPv6 support for the CloudFront distribution.
  #
  is_ipv6_enabled = true


  # ----------------------------------------------------------
  # HTTP Version
  # ----------------------------------------------------------
  #
  # Supports both HTTP/2 and HTTP/3.
  #
  # This matches the CloudFormation configuration:
  #
  #   HttpVersion: http2and3
  #
  http_version = "http2and3"


  # ==========================================================
  # S3 ORIGIN
  # ==========================================================
  #
  # Defines the existing Terraform-managed S3 bucket as the
  # CloudFront origin.
  #
  # IMPORTANT:
  #
  # The regional S3 endpoint is intentionally used here to
  # match the working CloudFormation configuration.
  #
  # Example:
  #
  #   bucket-name.s3.us-east-1.amazonaws.com
  #
  # ==========================================================

  origin {

    # --------------------------------------------------------
    # Regional S3 Bucket Endpoint
    # --------------------------------------------------------
    #
    # Uses the AWS provider region.
    #
    domain_name = aws_s3_bucket.lab.bucket_regional_domain_name


    # --------------------------------------------------------
    # Origin ID
    # --------------------------------------------------------
    #
    # Unique identifier used by CloudFront cache behaviors.
    #
    origin_id = "S3WebsiteOrigin"


    # --------------------------------------------------------
    # Origin Access Control
    # --------------------------------------------------------
    #
    # Attaches the OAC created above to the S3 origin.
    #
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id

  }


  # ==========================================================
  # DEFAULT CACHE BEHAVIOR
  # ==========================================================
  #
  # Defines how CloudFront handles requests that do not match
  # another cache behavior.
  #
  # ==========================================================

  default_cache_behavior {

    # --------------------------------------------------------
    # Target Origin
    # --------------------------------------------------------
    #
    # Sends requests to the S3 origin defined above.
    #
    target_origin_id = "S3WebsiteOrigin"


    # --------------------------------------------------------
    # Viewer Protocol Policy
    # --------------------------------------------------------
    #
    # HTTP requests are automatically redirected to HTTPS.
    #
    viewer_protocol_policy = "redirect-to-https"


    # --------------------------------------------------------
    # Allowed HTTP Methods
    # --------------------------------------------------------
    #
    # Allows read-only website requests plus OPTIONS.
    #
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]


    # --------------------------------------------------------
    # Cached HTTP Methods
    # --------------------------------------------------------
    #
    # Only GET and HEAD requests are cached.
    #
    cached_methods = [
      "GET",
      "HEAD"
    ]


    # --------------------------------------------------------
    # Compression
    # --------------------------------------------------------
    #
    # Enables CloudFront compression for supported content.
    #
    compress = true


    # --------------------------------------------------------
    # Forwarded Values
    # --------------------------------------------------------
    #
    # Matches the CloudFormation configuration.
    #
    # Query strings are not forwarded.
    # Cookies are not forwarded.
    #
    forwarded_values {

      # Do not forward query strings.
      query_string = false


      # Do not forward cookies.
      cookies {
        forward = "none"
      }
    }
  }


  # ==========================================================
  # CLOUDFRONT PRICE CLASS
  # ==========================================================
  #
  # PriceClass_100 uses CloudFront edge locations in the
  # lowest-cost CloudFront price class.
  #
  # Matches:
  #
  #   CloudFormation: PriceClass_100
  #
  # ==========================================================

  price_class = "PriceClass_100"


  # ==========================================================
  # GEOGRAPHIC RESTRICTIONS
  # ==========================================================
  #
  # No geographic restrictions are applied.
  #
  # Matches:
  #
  #   RestrictionType: none
  #
  # ==========================================================

  restrictions {

    geo_restriction {

      restriction_type = "none"
    }
  }


  # ==========================================================
  # VIEWER CERTIFICATE
  # ==========================================================
  #
  # Uses the default CloudFront SSL/TLS certificate.
  #
  # This provides HTTPS access through the default:
  #
  #   *.cloudfront.net
  #
  # domain.
  #
  # A custom ACM certificate is intentionally NOT configured
  # here because the CloudFormation version also uses the
  # default CloudFront certificate.
  #
  # ==========================================================

  viewer_certificate {

    cloudfront_default_certificate = true
  }
}


# ============================================================
# END OF CLOUDFRONT CONFIGURATION
# ============================================================