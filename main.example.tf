terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
  }

  # backend "s3" {
  #   bucket         = "example-terraform-state"
  #   region         = "eu-west-1"
  #   dynamodb_table = "example-terraform-state"
  #   encrypt        = true

  #   key = "example.com.tfstate"
  # }
}

locals {
  domain_name  = "example.com"
  project_name = "example"
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Project   = local.project_name
      ManagedBy = "terraform"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"

  default_tags {
    tags = {
      Project   = local.project_name
      ManagedBy = "terraform"
    }
  }
}

module "basic_route53_and_certificate" {
  source = "./basic-route53-and-certificate"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name = local.domain_name
}

module "s3_cloudfront" {
  source = "./s3-cloudfront"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  depends_on = [module.basic_route53_and_certificate]

  base_domain_name       = local.domain_name
  cloudfront_domain_name = local.domain_name
}

module "simple_email" {
  source = "./simple-email"

  depends_on = [module.basic_route53_and_certificate]

  domain_name = local.domain_name
}

module "lambda_api_gateway" {
  source = "./lambda-api-gateway"

  depends_on = [module.basic_route53_and_certificate]

  base_domain_name = local.domain_name
  api_domain_name  = "api.${local.domain_name}"
  function_zip     = "function.zip"
  function_layers  = [] // This should be an array of ARNs
}
