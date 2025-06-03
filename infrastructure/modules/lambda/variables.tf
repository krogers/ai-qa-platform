variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}

variable "s3_knowledge_bucket_name" {
  description = "Name of the knowledge base S3 bucket"
  type        = string
}

variable "s3_user_data_bucket_name" {
  description = "Name of the user data S3 bucket"
  type        = string
}


variable "bedrock_knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  type        = string
}

