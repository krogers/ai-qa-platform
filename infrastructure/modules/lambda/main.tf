data "archive_file" "api_handler" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/dist/lambdas/api-handler"
  output_path = "${path.root}/builds/api-handler.zip"
}

data "archive_file" "document_processor" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/dist/lambdas/document-processor"
  output_path = "${path.root}/builds/document-processor.zip"
}

data "archive_file" "embeddings_generator" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/dist/lambdas/embeddings-generator"
  output_path = "${path.root}/builds/embeddings-generator.zip"
}

resource "aws_lambda_function" "api_handler" {
  filename         = data.archive_file.api_handler.output_path
  function_name    = "${var.project_name}-api-handler-${var.environment}"
  role            = var.lambda_execution_role_arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.api_handler.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 512

  environment {
    variables = {
      BEDROCK_REGION             = data.aws_region.current.name
      BEDROCK_MODEL_ID           = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"
      BEDROCK_KNOWLEDGE_BASE_ID  = var.bedrock_knowledge_base_id
      S3_KNOWLEDGE_BUCKET        = var.s3_knowledge_bucket_name
      S3_USER_DATA_BUCKET        = var.s3_user_data_bucket_name
      NODE_ENV                   = var.environment
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "document_processor" {
  filename         = data.archive_file.document_processor.output_path
  function_name    = "${var.project_name}-document-processor-${var.environment}"
  role            = var.lambda_execution_role_arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.document_processor.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 300
  memory_size     = 1024

  environment {
    variables = {
      BEDROCK_REGION             = data.aws_region.current.name
      BEDROCK_KNOWLEDGE_BASE_ID  = var.bedrock_knowledge_base_id
      S3_KNOWLEDGE_BUCKET        = var.s3_knowledge_bucket_name
      NODE_ENV                   = var.environment
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "embeddings_generator" {
  filename         = data.archive_file.embeddings_generator.output_path
  function_name    = "${var.project_name}-embeddings-generator-${var.environment}"
  role            = var.lambda_execution_role_arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.embeddings_generator.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 60
  memory_size     = 512

  environment {
    variables = {
      BEDROCK_REGION             = data.aws_region.current.name
      BEDROCK_MODEL_ID           = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"
      BEDROCK_KNOWLEDGE_BASE_ID  = var.bedrock_knowledge_base_id
      NODE_ENV                   = var.environment
    }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "allow_s3_invoke_document_processor" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.document_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_knowledge_bucket_name}"
}

data "aws_region" "current" {}