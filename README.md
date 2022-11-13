# Terraform Modules

A collection of useful Terraform modules for AWS

See `main.example.tf` for an example

# basic-route53-and-certificate

- Creates a Hosted Zone for a domain
- Points the domain name servers to the created hosted zone
- Creates a ACM certificate (both in the default provider region and in us-east-1) and verifies it through DNS

# s3-cloudfront

- Creates a S3 Bucket that will serve as an origin for a CloudFront Distribution
- Creates a CloudFront Distribution with the said S3 Bucket as it's origin
- Creates an Alias record on the domain hosted zone that points to the CloudFront Distribution