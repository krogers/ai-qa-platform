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

variable "document_processor_lambda_arn" {
  description = "ARN of the document processor Lambda function"
  type        = string
  default     = ""
}

variable "lambda_permission_for_s3" {
  description = "Lambda permission for S3 to invoke function"
  type        = any
  default     = null
}