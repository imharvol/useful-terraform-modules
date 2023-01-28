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

# lambda-api-gateway
- Creates a Lambda function and creates a policy that allows it to create logs on Cloudwatch and allows API Gateway to invoke it
- Creates a API Gateway with an integration that forwards all requests to the lambda function that was created
- Creates and verifies a certificate for the domain that is going to point to the API Gateway
- Points the domain to the API Gateway

# simple-email
- Creates and verifies a SES identity for the domain (DKIM, FROM MX, FROM TXT, RECEIVING MX)
- Creates a S3 Bucket to store the emails
- Creates a receipt rule that stores received emails on the S3 Bucket