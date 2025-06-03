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
  description = "ARN of the S3 knowledge bucket"
  type        = string
}