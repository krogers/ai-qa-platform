output "api_handler_function_name" {
  description = "Name of the API handler Lambda function"
  value       = aws_lambda_function.api_handler.function_name
}

output "api_handler_function_arn" {
  description = "ARN of the API handler Lambda function"
  value       = aws_lambda_function.api_handler.arn
}

output "document_processor_function_name" {
  description = "Name of the document processor Lambda function"
  value       = aws_lambda_function.document_processor.function_name
}

output "document_processor_function_arn" {
  description = "ARN of the document processor Lambda function"
  value       = aws_lambda_function.document_processor.arn
}

output "embeddings_generator_function_name" {
  description = "Name of the embeddings generator Lambda function"
  value       = aws_lambda_function.embeddings_generator.function_name
}

output "embeddings_generator_function_arn" {
  description = "ARN of the embeddings generator Lambda function"
  value       = aws_lambda_function.embeddings_generator.arn
}

output "s3_lambda_permission" {
  description = "Lambda permission for S3 to invoke function"
  value       = aws_lambda_permission.allow_s3_invoke_document_processor
}