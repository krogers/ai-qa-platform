terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project_name = var.project_name
  environment  = var.environment
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

module "s3" {
  source = "./modules/s3"
  
  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
  
  document_processor_lambda_arn = module.lambda.document_processor_function_arn
  lambda_permission_for_s3      = module.lambda.s3_lambda_permission
}

module "iam" {
  source = "./modules/iam"
  
  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
  
  s3_knowledge_bucket_arn = module.s3.knowledge_bucket_arn
  s3_user_data_bucket_arn = module.s3.user_data_bucket_arn
}

module "lambda" {
  source = "./modules/lambda"
  
  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
  
  lambda_execution_role_arn = module.iam.lambda_execution_role_arn
  s3_knowledge_bucket_name  = module.s3.knowledge_bucket_name
  s3_user_data_bucket_name  = module.s3.user_data_bucket_name
  
  bedrock_knowledge_base_id   = module.bedrock.knowledge_base_id
}

module "api_gateway" {
  source = "./modules/api-gateway"
  
  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
  
  lambda_function_name = module.lambda.api_handler_function_name
  lambda_function_arn  = module.lambda.api_handler_function_arn
}

module "bedrock" {
  source = "./modules/bedrock"
  
  project_name = local.project_name
  environment  = local.environment
  tags         = local.common_tags
  
  s3_knowledge_bucket_arn   = module.s3.knowledge_bucket_arn
}