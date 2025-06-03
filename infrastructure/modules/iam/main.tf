data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.project_name}-lambda-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

data "aws_iam_policy_document" "lambda_s3_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      var.s3_knowledge_bucket_arn,
      "${var.s3_knowledge_bucket_arn}/*",
      var.s3_user_data_bucket_arn,
      "${var.s3_user_data_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${var.project_name}-lambda-s3-policy-${var.environment}"
  description = "IAM policy for Lambda to access S3 buckets"
  policy      = data.aws_iam_policy_document.lambda_s3_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

data "aws_iam_policy_document" "lambda_bedrock_policy" {
  statement {
    effect = "Allow"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:Retrieve"
    ]

    resources = [
      "arn:aws:bedrock:*::foundation-model/*",
      "arn:aws:bedrock:*:*:knowledge-base/*",
      "arn:aws:bedrock:*:*:inference-profile/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_bedrock_policy" {
  name        = "${var.project_name}-lambda-bedrock-policy-${var.environment}"
  description = "IAM policy for Lambda to access Bedrock"
  policy      = data.aws_iam_policy_document.lambda_bedrock_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock" {
  policy_arn = aws_iam_policy.lambda_bedrock_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}