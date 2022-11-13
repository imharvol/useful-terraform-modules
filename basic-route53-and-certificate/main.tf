# - Create a Route 53 Hosted Zone for var.domain_name
# - Create a ACM Certificate for var.domain_name. The certificate is created in the default region and in us-east-1 
# - Verify the ACM Certificates using DNS
# - Set var.domain_name Name Servers to the Hosted Zone we created

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "4.38.0"
      configuration_aliases = [aws, aws.us_east_1]
    }
  }
}

resource "aws_route53_zone" "domain" {
  name = var.domain_name

  force_destroy = true
}

resource "aws_acm_certificate" "domain_certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "domain_certificate_us_east_1" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  provider = aws.us_east_1

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "domain_certificate_records" {
  # aws_acm_certificate.domain_certificate.domain_validation_options is the same for all aws regions
  # so there's no need to also add the aws_acm_certificate.domain_certificate_us_east_1.domain_validation_options
  for_each = {
    for dvo in aws_acm_certificate.domain_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = aws_route53_zone.domain.zone_id
}

resource "aws_route53domains_registered_domain" "domain" {
  domain_name = var.domain_name

  dynamic "name_server" {
    for_each = aws_route53_zone.domain.name_servers
    content {
      name = name_server.value
    }
  }

  auto_renew    = true
  transfer_lock = true

  admin_privacy      = true
  registrant_privacy = true
  tech_privacy       = true
}
