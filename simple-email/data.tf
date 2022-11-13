data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "domain" {
  name = var.domain_name
}

data "aws_ses_active_receipt_rule_set" "main" {}
