resource "aws_ses_domain_identity" "domain" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "domain" {
  domain = aws_ses_domain_identity.domain.domain
}

resource "aws_ses_domain_mail_from" "domain" {
  domain           = aws_ses_domain_identity.domain.domain
  mail_from_domain = "bounce.${aws_ses_domain_identity.domain.domain}"
}

# This is not needed anymore. DKIM is enough
# resource "aws_route53_record" "domain_identity" {
#   zone_id = data.aws_route53_zone.domain.id
#   name    = "_amazonses.${aws_ses_domain_identity.domain.domain}"
#   type    = "TXT"
#   ttl     = "600"
#   records = [aws_ses_domain_identity.domain.verification_token]
# }

resource "aws_route53_record" "domain_dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.domain.id
  name    = "${aws_ses_domain_dkim.domain.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.domain.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.domain.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "domain_from_mx" {
  zone_id = data.aws_route53_zone.domain.id
  name    = aws_ses_domain_mail_from.domain.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

resource "aws_route53_record" "domain_from_txt" {
  zone_id = data.aws_route53_zone.domain.id
  name    = aws_ses_domain_mail_from.domain.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

# Email receiving https://docs.aws.amazon.com/ses/latest/dg/receiving-email-mx-record.html
resource "aws_route53_record" "domain_receiving" {
  zone_id = data.aws_route53_zone.domain.id
  name    = aws_ses_domain_identity.domain.domain
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}

resource "aws_s3_bucket" "email" {
  bucket = "${aws_ses_domain_identity.domain.domain}-ses"

  force_destroy = false
}

resource "aws_s3_bucket_ownership_controls" "email" {
  bucket = aws_s3_bucket.email.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "email" {
  depends_on = [aws_s3_bucket_ownership_controls.email]

  bucket = aws_s3_bucket.email.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "email" {
  bucket = aws_s3_bucket.email.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  aws_ses_receipt_rule_name = "${var.domain_name}-save-s3"
}

resource "aws_s3_bucket_policy" "email" {
  bucket = aws_s3_bucket.email.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowSESPuts",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ses.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "${aws_s3_bucket.email.arn}/*",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceAccount" : "${data.aws_caller_identity.current.account_id}",
            "AWS:SourceArn" : "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/${data.aws_ses_active_receipt_rule_set.main.rule_set_name}:receipt-rule/${local.aws_ses_receipt_rule_name}"
            #"AWS:SourceArn" : "${aws_ses_receipt_rule.store.arn}" # Can't do because of dependencies
          }
        }
      }
    ]
  })
}

resource "aws_ses_receipt_rule" "store" {
  depends_on = [
    aws_s3_bucket_policy.email
  ]

  name          = local.aws_ses_receipt_rule_name
  rule_set_name = data.aws_ses_active_receipt_rule_set.main.rule_set_name

  enabled      = true
  recipients   = [var.domain_name]
  scan_enabled = true

  s3_action {
    bucket_name = aws_s3_bucket.email.id
    position    = 1
  }
}
