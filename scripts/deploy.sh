#!/bin/bash

set -e

# AI Q&A Platform Deployment Script

ENVIRONMENT=${1:-dev}
PROJECT_NAME="ai-qa-platform"

echo "🚀 Starting deployment for environment: $ENVIRONMENT"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Environment must be dev, staging, or prod"
    exit 1
fi

# Check required tools
echo "🔍 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Build backend
echo "🔨 Building backend..."
cd backend

if [ ! -f "package.json" ]; then
    echo "❌ package.json not found in backend directory"
    exit 1
fi

npm install
npm run build
echo "⚠️  Skipping tests for deployment"

echo "✅ Backend build completed"

# Create builds directory for Terraform
mkdir -p ../infrastructure/builds

cd ../infrastructure

# Check for terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found. Please copy from terraform.tfvars.example and configure"
    exit 1
fi

# Initialize Terraform
echo "⚙️ Initializing Terraform..."
terraform init

# Select or create workspace
echo "🏗️ Setting up Terraform workspace..."
terraform workspace select $ENVIRONMENT 2>/dev/null || terraform workspace new $ENVIRONMENT

# Plan deployment
echo "📋 Planning Terraform deployment..."
terraform plan -var="environment=$ENVIRONMENT" -out="$ENVIRONMENT.tfplan"

# Ask for confirmation
read -p "🤔 Do you want to apply this plan? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply deployment
echo "🚀 Applying Terraform deployment..."
terraform apply "$ENVIRONMENT.tfplan"

# Get outputs
echo "📊 Deployment outputs:"
API_URL=$(terraform output -raw api_gateway_url)
KNOWLEDGE_BUCKET=$(terraform output -raw s3_knowledge_bucket_name)
USER_DATA_BUCKET=$(terraform output -raw s3_user_data_bucket_name)

echo "✅ Deployment completed successfully!"
echo ""
echo "📝 Important information:"
echo "  API Gateway URL: $API_URL"
echo "  Knowledge Bucket: $KNOWLEDGE_BUCKET"
echo "  User Data Bucket: $USER_DATA_BUCKET"
echo ""
echo "🧪 Test your deployment:"
echo "  curl -X POST $API_URL/graphql \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"query\": \"query { health }\"}'"
echo ""
echo "📚 Next steps:"
echo "  1. Upload documents to s3://$KNOWLEDGE_BUCKET/documents/"
echo "  2. Configure your frontend to use: $API_URL"
echo "  3. Monitor logs in CloudWatch"

# Cleanup
rm -f "$ENVIRONMENT.tfplan"

echo "🎉 Deployment script completed!"