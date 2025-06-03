output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.api_gateway.api_url
}

output "s3_knowledge_bucket_name" {
  description = "Name of the S3 knowledge base bucket"
  value       = module.s3.knowledge_bucket_name
}

output "s3_user_data_bucket_name" {
  description = "Name of the S3 user data bucket"
  value       = module.s3.user_data_bucket_name
}

output "lambda_api_handler_function_name" {
  description = "Name of the API handler Lambda function"
  value       = module.lambda.api_handler_function_name
}

output "lambda_document_processor_function_name" {
  description = "Name of the document processor Lambda function"
  value       = module.lambda.document_processor_function_name
}

output "lambda_embeddings_generator_function_name" {
  description = "Name of the embeddings generator Lambda function"
  value       = module.lambda.embeddings_generator_function_name
}

output "bedrock_knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base"
  value       = module.bedrock.knowledge_base_id
}

output "bedrock_knowledge_base_arn" {
  description = "ARN of the Bedrock Knowledge Base"
  value       = module.bedrock.knowledge_base_arn
}

output "bedrock_data_source_id" {
  description = "ID of the S3 data source for Knowledge Base"
  value       = module.bedrock.data_source_id
}

output "opensearch_collection_arn" {
  description = "ARN of the OpenSearch Serverless collection"
  value       = module.bedrock.opensearch_collection_arn
}