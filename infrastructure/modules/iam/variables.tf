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

variable "s3_knowledge_bucket_arn" {
  description = "ARN of the knowledge base S3 bucket"
  type        = string
}

variable "s3_user_data_bucket_arn" {
  description = "ARN of the user data S3 bucket"
  type        = string
}