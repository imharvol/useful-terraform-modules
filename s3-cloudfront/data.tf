data "aws_acm_certificate" "domain" {
  provider = aws.us_east_1

  domain   = var.cloudfront_domain_name
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "domain" {
  name = var.base_domain_name
}