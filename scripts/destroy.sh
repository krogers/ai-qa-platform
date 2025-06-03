#!/bin/bash

set -e

# AI Q&A Platform Destruction Script

ENVIRONMENT=${1:-dev}
PROJECT_NAME="ai-qa-platform"

echo "🔥 Starting infrastructure destruction for environment: $ENVIRONMENT"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Environment must be dev, staging, or prod"
    exit 1
fi

# Safety check for production
if [ "$ENVIRONMENT" = "prod" ]; then
    echo "⚠️  WARNING: You are about to destroy PRODUCTION infrastructure!"
    echo "⚠️  This action is IRREVERSIBLE and will delete all data!"
    echo ""
    read -p "Type 'destroy-production' to confirm: " -r
    echo
    if [[ $REPLY != "destroy-production" ]]; then
        echo "❌ Destruction cancelled"
        exit 1
    fi
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

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

echo "✅ Prerequisites check passed"

cd infrastructure

# Check if workspace exists
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    echo "❌ Terraform workspace '$ENVIRONMENT' does not exist"
    exit 1
fi

# Select workspace
echo "🏗️ Selecting Terraform workspace..."
terraform workspace select $ENVIRONMENT

# Get current state
echo "📋 Getting current infrastructure state..."
terraform refresh -var="environment=$ENVIRONMENT"

# Show what will be destroyed
echo "🔍 Planning destruction..."
terraform plan -destroy -var="environment=$ENVIRONMENT" -out="destroy-$ENVIRONMENT.tfplan"

# Ask for final confirmation
echo ""
echo "⚠️  The above resources will be PERMANENTLY DELETED!"
echo "⚠️  This includes:"
echo "  - All Lambda functions"
echo "  - S3 buckets and their contents"
echo "  - API Gateway"
echo "  - IAM roles and policies"
echo "  - CloudWatch logs"
echo ""
read -p "🤔 Are you absolutely sure you want to proceed? (type 'yes'): " -r
echo

if [[ $REPLY != "yes" ]]; then
    echo "❌ Destruction cancelled"
    rm -f "destroy-$ENVIRONMENT.tfplan"
    exit 1
fi

# Empty S3 buckets first (Terraform can't delete non-empty buckets)
echo "🗑️ Emptying S3 buckets..."

KNOWLEDGE_BUCKET=$(terraform output -raw s3_knowledge_bucket_name 2>/dev/null || echo "")
USER_DATA_BUCKET=$(terraform output -raw s3_user_data_bucket_name 2>/dev/null || echo "")

if [ ! -z "$KNOWLEDGE_BUCKET" ]; then
    echo "  Emptying knowledge bucket: $KNOWLEDGE_BUCKET"
    aws s3 rm "s3://$KNOWLEDGE_BUCKET" --recursive || true
fi

if [ ! -z "$USER_DATA_BUCKET" ]; then
    echo "  Emptying user data bucket: $USER_DATA_BUCKET"
    aws s3 rm "s3://$USER_DATA_BUCKET" --recursive || true
fi

# Apply destruction
echo "💥 Destroying infrastructure..."
terraform apply "destroy-$ENVIRONMENT.tfplan"

# Delete workspace if not default
if [ "$ENVIRONMENT" != "default" ]; then
    echo "🏗️ Switching to default workspace..."
    terraform workspace select default
    
    echo "🗑️ Deleting workspace: $ENVIRONMENT"
    terraform workspace delete "$ENVIRONMENT"
fi

# Cleanup
rm -f "destroy-$ENVIRONMENT.tfplan"

echo ""
echo "✅ Infrastructure destruction completed!"
echo ""
echo "🧹 Manual cleanup (if needed):"
echo "  - Check Pinecone for any remaining indices"
echo "  - Verify CloudWatch logs are removed"
echo "  - Check for any remaining resources in AWS console"

echo "🎉 Destruction script completed!"