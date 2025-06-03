# AI Q&A Platform

A scalable, cloud-hosted AI-powered Q&A application built with AWS services, featuring semantic search through AWS Bedrock Knowledge Base and natural language generation via Claude 3.7 Sonnet. Includes a responsive web frontend for interactive question-answering.

## 🏗️ Architecture

- **Frontend**: Responsive SPA with elegant UI and GraphQL API via AWS API Gateway
- **Backend**: AWS Lambda functions (Node.js/TypeScript)
- **AI/ML**: Amazon Bedrock (Claude 3.7 Sonnet) + Titan Embeddings
- **Vector DB**: AWS Bedrock Knowledge Base for semantic similarity search
- **Storage**: Amazon S3 for documents and user data
- **Context**: S3-based user history storage
- **Infrastructure**: Terraform for AWS resource provisioning

## 🚀 Quick Start

### 1. Environment Setup
```bash
# Clone and setup environment
./scripts/setup-env.sh
```

### 2. Configure Services
Edit the configuration files:

**Infrastructure configuration:**
```bash
# Copy and edit Terraform variables
cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
# Edit with your AWS region, env variables, etc.
```

**Backend configuration:**
```bash
# Edit environment variables for local development
vim backend/.env
```

**Frontend:**
```bash
# The frontend SPA is located at:
frontend/index.html
# Update the API URL in the SPA to match your deployed API Gateway endpoint
```

### 3. Deploy Infrastructure
```bash
# Deploy to development environment
./scripts/deploy.sh dev

# Deploy to production
./scripts/deploy.sh prod
```

### 4. Test the System
```bash
# Health check
curl -X POST https://your-api-url/dev/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query": "query { health }"}'

# Ask a question via API
curl -X POST https://your-api-url/dev/graphql \
  -H 'Content-Type: application/json' \
  -H 'X-User-Id: 550e8400-e29b-41d4-a716-446655440000' \
  -d '{
    "query": "mutation { askQuestion(input: { text: \"What does this application do?\", userId: \"550e8400-e29b-41d4-a716-446655440000\" }) { text confidence sources } }"
  }'

# Or use the web frontend
# Open frontend/index.html in a browser and interact with the UI
```

### 5. Rebuild Knowledge Base Index
```bash
# Trigger knowledge base re-indexing when needed
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id your-knowledge-base-id \
  --data-source-id your-data-source-id
```

## 📁 Project Structure

```
ai-qa-platform/
├── backend/                    # TypeScript/Node.js backend
│   ├── src/
│   │   ├── graphql/           # GraphQL schemas and resolvers
│   │   ├── services/          # AWS service integrations
│   │   ├── lambdas/           # Lambda function handlers
│   │   ├── types/             # TypeScript type definitions
│   │   └── utils/             # Utilities and helpers
│   ├── tests/                 # Unit and integration tests
│   └── package.json
├── frontend/                   # Responsive SPA frontend
│   └── index.html             # Complete SPA with elegant UI
├── infrastructure/             # Terraform infrastructure code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── api-gateway/       # API Gateway configuration
│   │   ├── lambda/            # Lambda functions
│   │   ├── s3/                # S3 buckets
│   │   ├── iam/               # IAM roles and policies
│   │   └── bedrock/           # Bedrock configuration
│   ├── environments/          # Environment-specific configs
│   └── main.tf
├── docs/                      # Documentation
│   ├── architecture.md        # System architecture
│   ├── deployment.md          # Deployment guide
│   └── api-reference.md       # API documentation
└── scripts/                   # Automation scripts
    ├── deploy.sh              # Deployment script
    ├── destroy.sh             # Infrastructure teardown
    └── setup-env.sh           # Environment setup
```

## 🔧 Development

### Backend Development
```bash
cd backend

# Install dependencies
npm install

# Build TypeScript
npm run build

# Run tests
npm test

# Watch mode for development
npm run test:watch

# Type checking
npm run type-check
```

### Infrastructure Development
```bash
cd infrastructure

# Initialize Terraform
terraform init

# Plan changes
terraform plan -var="environment=dev"

# Apply changes
terraform apply -var="environment=dev"

# Destroy infrastructure
terraform destroy -var="environment=dev"
```

## 📋 Prerequisites

### Required Tools
- **Node.js** >= 18.0
- **Terraform** >= 1.0
- **AWS CLI** configured with appropriate permissions
- **Git** for version control

### Required Services
- **AWS Account** with Bedrock access
- **AWS Bedrock Knowledge Base** configured

### AWS Permissions
Your AWS credentials need access to:
- IAM (roles, policies)
- Lambda (functions, layers)
- S3 (buckets, objects)
- API Gateway (REST APIs)
- Bedrock (model access)
- CloudWatch (logs)

## 🛠️ Configuration

### Environment Variables

#### Required for Infrastructure
```bash
# infrastructure/terraform.tfvars
aws_region           = "us-east-1"
project_name         = "ai-qa-platform"
environment          = "dev"
# Bedrock Knowledge Base configuration handled by Terraform
```

#### Required for Local Development
```bash
# backend/.env
NODE_ENV=development
BEDROCK_REGION=us-east-1
BEDROCK_MODEL_ID=anthropic.claude-3-5-sonnet-20241022-v2:0
S3_KNOWLEDGE_BUCKET=ai-qa-platform-knowledge-base-dev
S3_USER_DATA_BUCKET=ai-qa-platform-user-data-dev
```

## 📊 Data Flow

1. **Question Submission** → Frontend SPA or GraphQL API → Lambda Handler
2. **Vector Search** → AWS Bedrock Knowledge Base semantic similarity search
3. **Fallback Context** → S3 document retrieval (if needed)
4. **Context Assembly** → S3 service for user history
5. **AI Generation** → Bedrock Claude 3.7 Sonnet with enhanced system prompts
6. **Response Delivery** → GraphQL response to client/frontend

## 🔒 Security

- **Encryption**: All data encrypted in transit and at rest
- **IAM**: Least-privilege access controls
- **API Security**: CORS configuration and rate limiting

## 📈 Monitoring

- **CloudWatch Logs**: Structured logging for all components
- **CloudWatch Metrics**: Performance and error monitoring
- **AWS X-Ray**: Distributed tracing (optional)

## 💰 Cost Optimization

This application has been built to utilize as many AWS free tier services as possible. The primary cost center will be the hosted LLM usage.

## 🗂️ Documentation

- **[Architecture Overview](docs/architecture.md)**: System design and components
- **[Deployment Guide](docs/deployment.md)**: Detailed deployment instructions
- **[API Reference](docs/api-reference.md)**: GraphQL API documentation


## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the [documentation](docs/)
2. Search existing GitHub issues
3. Create a new issue with detailed information

## 🚧 Roadmap

- [x] Frontend web application (responsive SPA)
- [x] Real-time chat interface
- [ ] Multi-model LLM support
- [ ] Enhanced security features
- [ ] Performance optimizations
- [ ] Mobile app development