data "aws_route53_zone" "base_domain" {
  name = var.base_domain_name
}

resource "aws_acm_certificate" "api_domain" {
  domain_name       = var.api_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

// Verify the certificate
resource "aws_route53_record" "api_domain_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.api_domain.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.base_domain.zone_id
}

resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name = var.api_domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api_domain.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [
    aws_acm_certificate.api_domain,
    aws_route53_record.api_domain_certificate
  ]
}

// Point API Domain Alias to the API Gateway
resource "aws_route53_record" "api" {
  name    = var.api_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.base_domain.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_apigatewayv2_api_mapping" "domain" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain.id
  stage       = aws_apigatewayv2_stage.default.id
}
