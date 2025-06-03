# AI Q&A Platform - Deployment Guide

## Overview

This guide covers the complete deployment process for the AI-powered Q&A platform using Terraform for infrastructure provisioning and AWS services.

## Prerequisites

### Required Tools
- **Terraform** >= 1.0
- **Node.js** >= 18.0
- **npm** or **yarn**
- **AWS CLI** configured with appropriate permissions
- **Web Browser** for testing the frontend SPA

### AWS Permissions Required
Your AWS credentials must have permissions for:
- IAM (roles, policies)
- Lambda (functions, layers)
- S3 (buckets, objects)
- API Gateway (REST APIs)
- Bedrock (model access)
- CloudWatch (logs)

## Step 1: Environment Setup

### 1.1 Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID, Secret, Region, and output format
```

### 1.2 Enable Bedrock Model Access
1. Go to AWS Bedrock console
2. Navigate to "Model access"
3. Request access to Claude 3.5 Sonnet model
4. Wait for approval (may take a few hours)

### 1.3 Set Up Bedrock Knowledge Base
1. The knowledge base will be created automatically by Terraform
2. Documents uploaded to the S3 knowledge bucket will be automatically indexed
3. No manual setup required - fully managed by AWS

## Step 2: Backend Setup

### 2.1 Install Dependencies
```bash
cd backend
npm install
```

### 2.2 Build the Application
```bash
npm run build
```

### 2.3 Run Tests
```bash
npm test
```

## Step 3: Infrastructure Deployment

### 3.1 Configure Terraform Variables
```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
aws_region           = "us-east-1"
project_name         = "ai-qa-platform"
environment          = "dev"
# Bedrock Knowledge Base configuration is handled automatically
```

### 3.2 Initialize Terraform
```bash
terraform init
```

### 3.3 Plan Deployment
```bash
terraform plan
```

Review the planned changes carefully.

### 3.4 Deploy Infrastructure
```bash
terraform apply
```

Type `yes` when prompted to confirm deployment.

### 3.5 Note Output Values
After successful deployment, note these important outputs:
- `api_gateway_url`: Your GraphQL endpoint
- `s3_knowledge_bucket_name`: Upload documents here
- `bedrock_knowledge_base_id`: For re-indexing operations
- Lambda function names for monitoring

## Step 4: Post-Deployment Configuration

### 4.1 Upload Knowledge Base Documents
```bash
# Upload documents to the knowledge bucket
aws s3 cp your-document.txt s3://ai-qa-platform-knowledge-base-dev/documents/

# Trigger knowledge base re-indexing
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id your-knowledge-base-id \
  --data-source-id your-data-source-id

# The system will automatically:
# 1. Process the document
# 2. Create embeddings via Bedrock
# 3. Index in the Knowledge Base
```

### 4.2 Test the System

#### Test the Frontend
1. Update the API URL in `frontend/index.html` to match your deployed endpoint
2. Open `frontend/index.html` in a web browser
3. Use the responsive chat interface to ask questions about Kevin Rogers

#### Test the API Directly
```bash
# Test health endpoint
curl -X POST \
  https://your-api-gateway-url/dev/graphql \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "query { health }"
  }'

# Test question submission
curl -X POST \
  https://your-api-gateway-url/dev/graphql \
  -H 'Content-Type: application/json' \
  -H 'X-User-Id: 550e8400-e29b-41d4-a716-446655440000' \
  -d '{
    "query": "mutation { askQuestion(input: { text: \"What is AI?\", userId: \"550e8400-e29b-41d4-a716-446655440000\" }) { id text confidence sources } }"
  }'
```

## Step 5: Monitoring and Logs

### 5.1 CloudWatch Logs
Monitor Lambda function logs:
```bash
# API Handler logs
aws logs tail /aws/lambda/ai-qa-platform-api-handler-dev --follow

# Document Processor logs
aws logs tail /aws/lambda/ai-qa-platform-document-processor-dev --follow
```

### 5.2 Check Lambda Function Status
```bash
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `ai-qa-platform`)].{Name:FunctionName,State:State,LastModified:LastModified}'
```

## Environment-Specific Deployments

### Development Environment
```bash
terraform workspace new dev
terraform apply -var="environment=dev"
```

### Staging Environment
```bash
terraform workspace new staging
terraform apply -var="environment=staging" -var="pinecone_index_name=ai-qa-knowledge-base-staging"
```

### Production Environment
```bash
terraform workspace new prod
terraform apply -var="environment=prod" -var="pinecone_index_name=ai-qa-knowledge-base-prod"
```

## Troubleshooting

### Common Issues

1. **Bedrock Access Denied**
   - Ensure model access is approved in Bedrock console
   - Verify IAM permissions for Bedrock

2. **Bedrock Knowledge Base Errors**
   - Verify knowledge base is created and active
   - Check data source configuration and S3 bucket permissions

3. **Lambda Timeout Errors**
   - Check CloudWatch logs for detailed error messages
   - Consider increasing Lambda timeout in Terraform
   - Verify Bedrock model access permissions

4. **Knowledge Base Ingestion Issues**
   - Check S3 bucket permissions for Bedrock access
   - Verify document formats are supported
   - Monitor ingestion job status in Bedrock console

### Debug Commands
```bash
# Check Terraform state
terraform show

# Validate configuration
terraform validate

# Check resource status
terraform refresh
```

## Security Considerations

1. **API Keys**: Store sensitive values in AWS Secrets Manager for production
2. **CORS**: Configure API Gateway CORS for your frontend domain
3. **Rate Limiting**: Implement API throttling for production use
4. **VPC**: Consider deploying Lambda functions in VPC for enhanced security
5. **Frontend Security**: Serve the SPA over HTTPS in production
6. **CORS Configuration**: Restrict CORS origins to your domain in production

## Cost Optimization

1. **Lambda**: Functions use pay-per-request pricing
2. **S3**: Use lifecycle policies for older documents
3. **Bedrock**: Monitor token usage and implement caching
4. **Knowledge Base**: Monitor query volume and optimize retrieval configuration

## Next Steps

1. Set up CI/CD pipeline for automated deployments
2. Implement monitoring and alerting
3. Configure custom domain name for the frontend SPA
4. Set up backup and disaster recovery procedures
5. Optimize frontend performance with CDN
6. Implement authentication and user management
7. Add advanced analytics and usage tracking