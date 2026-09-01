# ============================================================
# Terraform - CloudFront Origin Access Control (OAC)
# ============================================================
#
# Creates an Origin Access Control (OAC) that allows
# CloudFront to securely access the S3 bucket.
#
# OAC uses AWS Signature Version 4 (SigV4) to authenticate
# CloudFront requests to the S3 origin.
#
# This is the recommended approach for securing an S3 bucket
# behind CloudFront.
# ============================================================


# ------------------------------------------------------------
# CloudFront Origin Access Control
# ------------------------------------------------------------
# Creates an OAC that allows CloudFront to securely sign
# requests sent to the S3 origin.
# ------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "website" {

  # Unique name for the CloudFront OAC.
  # The S3 bucket name is included to make the OAC easy to
  # identify in the AWS Management Console.
  name = "${var.bucket_name}-oac"

  # Description explaining the purpose of this OAC.
  description = "CloudFront OAC for S3 website"

  # Specifies that the protected origin is an Amazon S3 bucket.
  origin_access_control_origin_type = "s3"

  # CloudFront signs every request sent to S3.
  signing_behavior = "always"

  # Use AWS Signature Version 4 (SigV4).
  signing_protocol = "sigv4"
}


# ============================================================
# CloudFront Distribution
# ============================================================
#
# Creates a CloudFront distribution in front of the S3
# website bucket.
# ============================================================

resource "aws_cloudfront_distribution" "website" {

  enabled = true

  comment = "Charlie Cafe S3 Website"

  default_root_object = "index.html"

  is_ipv6_enabled = true

  http_version = "http2and3"


  # ----------------------------------------------------------
  # S3 Origin
  # ----------------------------------------------------------

  origin {

    # S3 bucket endpoint.
    domain_name = "${var.bucket_name}.s3.amazonaws.com"

    # CloudFront origin identifier.
    origin_id = "S3WebsiteOrigin"

    # Attach the OAC created above.
    origin_access_control_id =
      aws_cloudfront_origin_access_control.website.id
  }


  # ----------------------------------------------------------
  # Default Cache Behavior
  # ----------------------------------------------------------

  default_cache_behavior {

    target_origin_id = "S3WebsiteOrigin"

    # Redirect HTTP requests to HTTPS.
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    # Enable CloudFront compression.
    compress = true

    forwarded_values {

      # Do not forward query strings.
      query_string = false

      # Do not forward cookies.
      cookies {
        forward = "none"
      }
    }
  }


  # ----------------------------------------------------------
  # Price Class
  # ----------------------------------------------------------

  price_class = "PriceClass_100"


  # ----------------------------------------------------------
  # Geographic Restrictions
  # ----------------------------------------------------------

  restrictions {

    geo_restriction {

      # No geographic restrictions.
      restriction_type = "none"
    }
  }


  # ----------------------------------------------------------
  # Viewer Certificate
  # ----------------------------------------------------------

  viewer_certificate {

    # Use the default CloudFront certificate.
    cloudfront_default_certificate = true
  }
}



# ============================================================
# CloudFront Distribution
# ============================================================
# Creates a CloudFront distribution in front of the S3 website.
#
# CloudFront provides:
#   - HTTPS access
#   - Global content delivery
#   - Caching
#   - Compression
#   - S3 Origin Access Control (OAC)
# ============================================================

resource "aws_cloudfront_distribution" "website" {

  # Enable the CloudFront distribution.
  enabled = true

  # Description displayed in AWS.
  comment = "Charlie Cafe S3 Website"

  # Default page returned when accessing the root URL.
  default_root_object = "index.html"

  # Enable IPv6.
  is_ipv6_enabled = true

  # Support HTTP/2 and HTTP/3.
  http_version = "http2and3"


  # ==========================================================
  # S3 Origin
  # ==========================================================

  origin {

    # S3 bucket used as the CloudFront origin.
    domain_name = "${var.bucket_name}.s3.amazonaws.com"

    # Unique identifier for this origin.
    origin_id = "S3WebsiteOrigin"

    # Use the CloudFront Origin Access Control created earlier.
    origin_access_control_id =
      aws_cloudfront_origin_access_control.website.id
  }


  # ==========================================================
  # Default Cache Behavior
  # ==========================================================

  default_cache_behavior {

    # Use the S3 origin defined above.
    target_origin_id = "S3WebsiteOrigin"

    # Redirect HTTP requests to HTTPS.
    viewer_protocol_policy = "redirect-to-https"

    # Allowed HTTP methods.
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    # Methods that CloudFront caches.
    cached_methods = [
      "GET",
      "HEAD"
    ]

    # Enable compression.
    compress = true

    # Forwarding configuration.
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
  # CloudFront Price Class
  # ==========================================================

  price_class = "PriceClass_100"


  # ==========================================================
  # Geographic Restrictions
  # ==========================================================

  restrictions {

    geo_restriction {

      # No geographic restriction.
      restriction_type = "none"
    }
  }


  # ==========================================================
  # Viewer Certificate
  # ==========================================================

  viewer_certificate {

    # Use the default CloudFront certificate.
    cloudfront_default_certificate = true
  }
}