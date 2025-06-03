#!/bin/bash

set -e

# AI Q&A Platform Environment Setup Script

echo "🛠️ Setting up AI Q&A Platform development environment"

# Check if running on macOS or Linux
OS=$(uname -s)
echo "🖥️ Detected OS: $OS"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install with package manager
install_package() {
    if [[ "$OS" == "Darwin" ]]; then
        if command_exists brew; then
            brew install "$1"
        else
            echo "❌ Homebrew not found. Please install Homebrew first: https://brew.sh/"
            exit 1
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y "$1"
        elif command_exists yum; then
            sudo yum install -y "$1"
        else
            echo "❌ Package manager not found. Please install $1 manually."
            exit 1
        fi
    else
        echo "❌ Unsupported OS: $OS"
        exit 1
    fi
}

# Check and install Node.js
echo "🔍 Checking Node.js..."
if command_exists node; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js found: $NODE_VERSION"
    
    # Check if version is >= 18
    if [[ $(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1) -lt 18 ]]; then
        echo "⚠️  Node.js version is less than 18. Please upgrade."
        exit 1
    fi
else
    echo "📦 Installing Node.js..."
    if [[ "$OS" == "Darwin" ]]; then
        install_package node
    else
        # Install Node.js 18.x on Linux
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
fi

# Check and install npm
echo "🔍 Checking npm..."
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm found: $NPM_VERSION"
else
    echo "❌ npm not found. Please install npm manually."
    exit 1
fi

# Check and install Terraform
echo "🔍 Checking Terraform..."
if command_exists terraform; then
    TERRAFORM_VERSION=$(terraform --version | head -n1)
    echo "✅ Terraform found: $TERRAFORM_VERSION"
else
    echo "📦 Installing Terraform..."
    if [[ "$OS" == "Darwin" ]]; then
        install_package terraform
    else
        # Install Terraform on Linux
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    fi
fi

# Check and install AWS CLI
echo "🔍 Checking AWS CLI..."
if command_exists aws; then
    AWS_VERSION=$(aws --version)
    echo "✅ AWS CLI found: $AWS_VERSION"
else
    echo "📦 Installing AWS CLI..."
    if [[ "$OS" == "Darwin" ]]; then
        install_package awscli
    else
        # Install AWS CLI v2 on Linux
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi
fi

# Check Git
echo "🔍 Checking Git..."
if command_exists git; then
    GIT_VERSION=$(git --version)
    echo "✅ Git found: $GIT_VERSION"
else
    echo "📦 Installing Git..."
    install_package git
fi

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
npm install
echo "✅ Backend dependencies installed"

cd ..

# Setup environment files
echo "⚙️ Setting up environment files..."

# Copy Terraform variables template
if [ ! -f "infrastructure/terraform.tfvars" ]; then
    cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars
    echo "📝 Created infrastructure/terraform.tfvars from template"
    echo "⚠️  Please edit infrastructure/terraform.tfvars with your configuration"
else
    echo "✅ infrastructure/terraform.tfvars already exists"
fi

# Create .env file for local development
if [ ! -f "backend/.env" ]; then
    cat > backend/.env << EOF
# Local development environment variables
NODE_ENV=development
BEDROCK_REGION=us-east-1
BEDROCK_MODEL_ID=anthropic.claude-3-7-sonnet-20250219-v1:0
BEDROCK_KNOWLEDGE_BASE_ID=your-knowledge-base-id
S3_KNOWLEDGE_BUCKET=ai-qa-platform-knowledge-base-dev
S3_USER_DATA_BUCKET=ai-qa-platform-user-data-dev
EOF
    echo "📝 Created backend/.env for local development"
    echo "⚠️  Please edit backend/.env with your configuration"
else
    echo "✅ backend/.env already exists"
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << EOF
# Dependencies
node_modules/
*/node_modules/

# Build outputs
dist/
build/
*.js.map

# Environment files
.env
.env.local
.env.development
.env.test
.env.production
*.tfvars
!*.tfvars.example

# Terraform
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl
terraform.tfplan
*.tfplan

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log
npm-debug.log*

# Coverage
coverage/

# Temporary files
tmp/
temp/
EOF
    echo "📝 Created .gitignore"
else
    echo "✅ .gitignore already exists"
fi

# Create README if it doesn't exist
if [ ! -f "README.md" ]; then
    cat > README.md << EOF
# AI Q&A Platform

A cloud-hosted AI-powered Q&A application using AWS services, Bedrock Knowledge Base, and Claude 3.7 Sonnet.

## Quick Start

1. **Setup Environment**
   \`\`\`bash
   ./scripts/setup-env.sh
   \`\`\`

2. **Configure Variables**
   - Edit \`infrastructure/terraform.tfvars\`
   - Edit \`backend/.env\` for local development

3. **Deploy Infrastructure**
   \`\`\`bash
   ./scripts/deploy.sh dev
   \`\`\`

4. **Test the API**
   \`\`\`bash
   curl -X POST https://your-api-url/dev/graphql \\
     -H 'Content-Type: application/json' \\
     -d '{"query": "query { health }"}'
   \`\`\`

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Deployment Guide](docs/deployment.md)
- [API Reference](docs/api-reference.md)

## Development

\`\`\`bash
cd backend
npm install
npm run build
npm test
\`\`\`

## Infrastructure

\`\`\`bash
cd infrastructure
terraform init
terraform plan
terraform apply
\`\`\`
EOF
    echo "📝 Created README.md"
else
    echo "✅ README.md already exists"
fi

echo ""
echo "🎉 Environment setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Configure AWS credentials: aws configure"
echo "  2. Enable Bedrock model access in AWS console"
echo "  3. Edit infrastructure/terraform.tfvars with your values"
echo "  4. Edit backend/.env for local development"
echo "  5. Run deployment: ./scripts/deploy.sh dev"
echo ""
echo "📚 Documentation available in docs/ directory"
echo "🚀 Ready to deploy: ./scripts/deploy.sh dev"