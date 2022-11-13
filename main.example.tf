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

  project_name = local.project_name
  domain_name  = local.domain_name

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

module "s3_cloudfront" {
  source = "./s3-cloudfront"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name = local.project_name
  domain_name  = local.domain_name

  depends_on = [module.basic_route53_and_certificate]
}
