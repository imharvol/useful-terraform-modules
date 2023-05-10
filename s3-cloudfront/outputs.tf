output "website_bucket_name" {
  description = "Website bucket name"
  value       = aws_s3_bucket.website.bucket
}
