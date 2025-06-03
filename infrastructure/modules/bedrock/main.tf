# CloudWatch Log Group for Bedrock
resource "aws_cloudwatch_log_group" "bedrock_logs" {
  name              = "/aws/bedrock/${var.project_name}-${var.environment}"
  retention_in_days = 30
  tags              = var.tags
}

# Note: Bedrock Knowledge Base automatically handles vector storage
# No external vector database configuration needed

# IAM role for Bedrock Knowledge Base
resource "aws_iam_role" "bedrock_knowledge_base_role" {
  name = "${var.project_name}-bedrock-kb-role-${var.environment}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Bedrock Knowledge Base to access S3
resource "aws_iam_policy" "bedrock_knowledge_base_s3_policy" {
  name        = "${var.project_name}-bedrock-kb-s3-policy-${var.environment}"
  description = "Policy for Bedrock Knowledge Base to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_knowledge_bucket_arn,
          "${var.s3_knowledge_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Note: Secrets Manager policy removed for development setup

# IAM policy for Bedrock Knowledge Base to invoke models
resource "aws_iam_policy" "bedrock_knowledge_base_model_policy" {
  name        = "${var.project_name}-bedrock-kb-model-policy-${var.environment}"
  description = "Policy for Bedrock Knowledge Base to invoke foundation models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:GetFoundationModel",
          "bedrock:ListFoundationModels"
        ]
        Resource = [
          "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/amazon.titan-embed-text-v1"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:GetFoundationModel",
          "bedrock:ListFoundationModels"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM policy for Bedrock Knowledge Base to access OpenSearch Serverless
resource "aws_iam_policy" "bedrock_knowledge_base_aoss_policy" {
  name        = "${var.project_name}-bedrock-kb-aoss-policy-${var.environment}"
  description = "Policy for Bedrock Knowledge Base to access OpenSearch Serverless"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = aws_opensearchserverless_collection.knowledge_base.arn
      }
    ]
  })
}

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "bedrock_kb_s3_policy" {
  policy_arn = aws_iam_policy.bedrock_knowledge_base_s3_policy.arn
  role       = aws_iam_role.bedrock_knowledge_base_role.name
}

resource "aws_iam_role_policy_attachment" "bedrock_kb_model_policy" {
  policy_arn = aws_iam_policy.bedrock_knowledge_base_model_policy.arn
  role       = aws_iam_role.bedrock_knowledge_base_role.name
}

resource "aws_iam_role_policy_attachment" "bedrock_kb_aoss_policy" {
  policy_arn = aws_iam_policy.bedrock_knowledge_base_aoss_policy.arn
  role       = aws_iam_role.bedrock_knowledge_base_role.name
}

# Data source to get current AWS region
data "aws_region" "current" {}

# Data source to get current caller identity
data "aws_caller_identity" "current" {}

# OpenSearch Serverless Collection for Knowledge Base
resource "aws_opensearchserverless_security_policy" "knowledge_base_encryption" {
  name = "ai-qa-kb-encrypt-${var.environment}-v2"
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource = [
          "collection/ai-qa-kb-${var.environment}-v2"
        ]
      }
    ]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "knowledge_base_network" {
  name = "ai-qa-kb-network-${var.environment}-v2"
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/ai-qa-kb-${var.environment}-v2"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/ai-qa-kb-${var.environment}-v2"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "knowledge_base_data" {
  name = "ai-qa-kb-data-${var.environment}-v2"
  type = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/ai-qa-kb-${var.environment}-v2"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DeleteCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DescribeCollectionItems"
          ]
        },
        {
          ResourceType = "index"
          Resource = [
            "index/ai-qa-kb-${var.environment}-v2/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument"
          ]
        }
      ]
      Principal = [
        aws_iam_role.bedrock_knowledge_base_role.arn,
        data.aws_caller_identity.current.arn
      ]
    }
  ])
}

resource "aws_opensearchserverless_collection" "knowledge_base" {
  name = "ai-qa-kb-${var.environment}-v2"
  type = "VECTORSEARCH"
  
  # Remove tags to avoid ListTagsForResource permission issue
  tags = {}

  depends_on = [
    aws_opensearchserverless_security_policy.knowledge_base_encryption,
    aws_opensearchserverless_security_policy.knowledge_base_network,
    aws_opensearchserverless_access_policy.knowledge_base_data
  ]
}

# Wait for OpenSearch collection to be fully ready
resource "time_sleep" "wait_for_opensearch" {
  depends_on = [aws_opensearchserverless_collection.knowledge_base]
  create_duration = "120s"
}

# Simple wait for collection to be active
resource "null_resource" "wait_for_collection_active" {
  depends_on = [time_sleep.wait_for_opensearch]
  
  provisioner "local-exec" {
    command = "echo 'Waiting for OpenSearch collection to be fully operational...'"
  }
}

# Create the vector index in OpenSearch Serverless using Python script
resource "null_resource" "create_vector_index" {
  depends_on = [null_resource.wait_for_collection_active]
  
  provisioner "local-exec" {
    command = <<-EOT
      python3 -c "
import boto3
import json
import requests
from requests_aws4auth import AWS4Auth

# AWS credentials and region
region = '${data.aws_region.current.name}'
service = 'aoss'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

# Collection endpoint
endpoint = '${aws_opensearchserverless_collection.knowledge_base.collection_endpoint}'
index_name = 'bedrock-kb-index'
url = f'{endpoint}/{index_name}'

# Index configuration
index_config = {
    'settings': {
        'index': {
            'knn': True,
            'knn.algo_param.ef_search': 512
        }
    },
    'mappings': {
        'properties': {
            'vector': {
                'type': 'knn_vector',
                'dimension': 1536,
                'method': {
                    'name': 'hnsw',
                    'space_type': 'cosinesimil',
                    'engine': 'nmslib'
                }
            },
            'text': {
                'type': 'text'
            },
            'metadata': {
                'type': 'object'
            }
        }
    }
}

try:
    response = requests.put(url, auth=awsauth, json=index_config, headers={'Content-Type': 'application/json'})
    print(f'Index creation response: {response.status_code} - {response.text}')
    if response.status_code in [200, 201]:
        print('Index created successfully')
    else:
        print('Index creation failed, but continuing...')
except Exception as e:
    print(f'Error creating index: {e}')
    print('Continuing anyway...')
" || echo "Python script failed, continuing anyway..."
    EOT
  }
  
  # Also add a destroy provisioner to clean up
  provisioner "local-exec" {
    when = destroy
    command = "echo 'Vector index will be automatically deleted with collection'"
  }
}

# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "main" {
  name        = "${var.project_name}-knowledge-base-${var.environment}"
  description = "Knowledge base for AI Q&A platform using S3 and OpenSearch Serverless"
  role_arn    = aws_iam_role.bedrock_knowledge_base_role.arn

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/amazon.titan-embed-text-v1"
    }
    type = "VECTOR"
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.knowledge_base.arn
      vector_index_name = "bedrock-kb-index"
      field_mapping {
        vector_field   = "vector"
        text_field     = "text"
        metadata_field = "metadata"
      }
    }
  }

  tags = var.tags

  depends_on = [
    null_resource.create_vector_index,
    aws_iam_role_policy_attachment.bedrock_kb_s3_policy,
    aws_iam_role_policy_attachment.bedrock_kb_model_policy,
    aws_iam_role_policy_attachment.bedrock_kb_aoss_policy
  ]
}

# Bedrock Knowledge Base Data Source
resource "aws_bedrockagent_data_source" "s3_data_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = "${var.project_name}-s3-data-source-${var.environment}"
  description       = "S3 data source for knowledge base"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.s3_knowledge_bucket_arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }

  depends_on = [aws_bedrockagent_knowledge_base.main]
}