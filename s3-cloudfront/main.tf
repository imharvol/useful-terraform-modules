# - Create a S3 Bucket as origin for CloudFront and disable all public access to the bucket except for CloudFront
# - Create a CloudFront distribution for var.domain_name
# - Create an Alias record on var.domain_name's hosted zone that points to CloudFront

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "4.38.0"
      configuration_aliases = [aws, aws.us_east_1]
    }
  }
}

# S3

resource "aws_s3_bucket" "website" {
  bucket = var.domain_name

  force_destroy = true
}

resource "aws_s3_bucket_acl" "website" {
  bucket = aws_s3_bucket.website.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Id" : "PolicyForCloudFrontPrivateContent",
    "Statement" : [
      {
        "Sid" : "AllowCloudFrontServicePrincipal",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        },
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.website.arn}/*",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceArn" : "${aws_cloudfront_distribution.website.arn}"
          }
        }
      }
    ]
  })
}

# CloudFront

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = aws_s3_bucket.website.id
  description                       = "${aws_s3_bucket.website.id} S3-Cloudfront Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = "s3"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2and3"

  aliases = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "s3"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
  }

  price_class = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.domain.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
}

# Route 53

resource "aws_route53_record" "domain_cloudfront" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
