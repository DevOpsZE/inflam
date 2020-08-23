# Output variable definitions

output "arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.s3-static-website.arn
}

output "name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.s3-static-website.id
}

output "website_endpoint" {
  description = "Domain name of the bucket"
  value       = aws_s3_bucket.s3-static-website.website_endpoint
}
