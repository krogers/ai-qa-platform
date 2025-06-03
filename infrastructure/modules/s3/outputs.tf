output "knowledge_bucket_name" {
  description = "Name of the knowledge base S3 bucket"
  value       = aws_s3_bucket.knowledge_base.bucket
}

output "knowledge_bucket_arn" {
  description = "ARN of the knowledge base S3 bucket"
  value       = aws_s3_bucket.knowledge_base.arn
}

output "user_data_bucket_name" {
  description = "Name of the user data S3 bucket"
  value       = aws_s3_bucket.user_data.bucket
}

output "user_data_bucket_arn" {
  description = "ARN of the user data S3 bucket"
  value       = aws_s3_bucket.user_data.arn
}