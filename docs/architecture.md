# AI Q&A Platform - Architecture Overview

## System Architecture

The AI Q&A Platform is built using a serverless, cloud-native architecture on AWS, designed for scalability, cost-effectiveness, and maintainability. The system now includes a responsive web frontend and uses AWS Bedrock Knowledge Base for semantic search.

```
┌─────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│                     │    │                  │    │                 │
│  Responsive SPA     │───▶│   API Gateway    │───▶│  Lambda Handler │
│  (Frontend UI)      │    │    (GraphQL)     │    │    (GraphQL)    │
│                     │    │                  │    │                 │
└─────────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                ┌───────────────────────┼───────────────────────┐
                                │                       │                       │
                                ▼                       ▼                       ▼
                    ┌─────────────────────┐    ┌─────────────────┐    ┌─────────────────┐
                    │                     │    │                 │    │                 │
                    │ Bedrock Knowledge   │    │  Amazon S3      │    │  Amazon S3      │
                    │ Base (Vector Search)│    │ (Documents)     │    │ (User History)  │
                    │                     │    │                 │    │                 │
                    └─────────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                ┌───────────────────────┼───────────────────────┐
                                │                       │                       │
                                ▼                       ▼                       ▼
                    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
                    │                 │    │                 │    │                 │
                    │  Doc Processor  │    │  Amazon Bedrock │    │   Embeddings    │
                    │    Lambda       │    │(Claude 3.7 Sonnet)│   │   Generator     │
                    │                 │    │                 │    │                 │
                    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Components

### 1. API Layer

#### API Gateway (REST)
- **Purpose**: Expose GraphQL endpoint with CORS support
- **Features**: Request/response transformation, throttling, authentication
- **Endpoints**: `/graphql` (POST), health checks
- **Security**: CORS headers, rate limiting

#### Lambda API Handler
- **Runtime**: Node.js 18.x
- **Framework**: Apollo Server Lambda
- **Memory**: 512 MB
- **Timeout**: 30 seconds
- **Features**: GraphQL schema execution, error handling, logging

### 2. Data Processing Layer

#### Document Processor Lambda
- **Trigger**: S3 ObjectCreated events
- **Runtime**: Node.js 18.x
- **Memory**: 1024 MB
- **Timeout**: 5 minutes
- **Function**: Text chunking, embedding generation, vector storage

#### Embeddings Generator Lambda
- **Trigger**: Direct invocation or API Gateway
- **Runtime**: Node.js 18.x
- **Memory**: 512 MB
- **Timeout**: 60 seconds
- **Function**: On-demand embedding generation

### 3. Storage Layer

#### Amazon S3
- **Knowledge Base Bucket**: Stores reference documents
- **User Data Bucket**: Stores user-specific data
- **Features**: Versioning, encryption, lifecycle policies
- **Triggers**: Lambda invocation on object creation

#### AWS Bedrock Knowledge Base
- **Purpose**: Semantic similarity search with managed vector storage
- **Configuration**: 
  - Vector Store: Amazon OpenSearch Serverless
  - Embeddings: Titan Text Embeddings v1 (1536 dimensions)
  - Retrieval: Hybrid search with semantic and keyword matching
- **Scaling**: Automatic AWS managed scaling
- **Data Sources**: S3 bucket integration with automatic ingestion

### 4. AI/ML Services

#### Amazon Bedrock
- **Model**: Claude 3.7 Sonnet (anthropic.claude-3-7-sonnet-20250219-v1:0)
- **Purpose**: Natural language generation with enhanced reasoning
- **Features**: Streaming responses, context-aware generation, enhanced system prompts
- **Integration**: AWS SDK with IAM role-based access
- **System Prompts**: Specialized for Kevin Rogers Q&A with content restrictions

#### Titan Embeddings
- **Model**: amazon.titan-embed-text-v1
- **Purpose**: Text vectorization for semantic search
- **Dimensions**: 1536-dimensional vectors

### 5. Context Management

#### S3-Based User History
- **Purpose**: User session and conversation history storage
- **Integration**: Direct S3 service integration
- **Data**: Conversation history (up to 50 messages per user)
- **Storage**: JSON format in user data bucket

## Data Flow

### Question Processing Pipeline

1. **Request Reception**
   ```
   Client → API Gateway → Lambda API Handler
   ```

2. **Vector Search**
   ```
   GraphQL Resolver → Bedrock Knowledge Base Service → AWS Knowledge Base
   ```

3. **Fallback Context**
   ```
   (If vector search yields low confidence)
   S3 Service → Knowledge Base Bucket
   ```

4. **Context Assembly**
   ```
   S3 User History Service → User History + Current Context
   ```

5. **AI Generation**
   ```
   Bedrock Service → Claude 3.5 Sonnet → Generated Response
   ```

6. **Response & History**
   ```
   S3 User History Service ← Save Interaction
   Client ← GraphQL Response
   ```

### Document Ingestion Pipeline

1. **Document Upload**
   ```
   Admin → S3 Knowledge Bucket
   ```

2. **Automatic Processing**
   ```
   S3 Event → Document Processor Lambda
   ```

3. **Text Chunking**
   ```
   Lambda → Text Segmentation (1000 chars, 200 overlap)
   ```

4. **Embedding Generation**
   ```
   Lambda → Bedrock Titan → Vector Embeddings
   ```

5. **Vector Storage**
   ```
   Lambda → Bedrock Knowledge Base → Automatic Indexing
   ```

## Security Architecture

### IAM Roles and Policies

#### Lambda Execution Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-7-sonnet-20250219-v1:0"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::knowledge-bucket/*",
        "arn:aws:s3:::user-data-bucket/*"
      ]
    }
  ]
}
```

### Network Security
- **VPC**: Optional VPC deployment for enhanced isolation
- **HTTPS**: TLS 1.2+ for all API communications
- **CORS**: Configurable origin restrictions

### Data Protection
- **Encryption at Rest**: S3 server-side encryption (AES-256)
- **Encryption in Transit**: HTTPS/TLS for all communications
- **Access Logging**: CloudWatch logs for all requests

## Scalability Considerations

### Auto-Scaling Components
- **Lambda**: Automatic scaling up to 1000 concurrent executions
- **API Gateway**: 10,000 requests/second default limit
- **Bedrock Knowledge Base**: Automatic AWS managed scaling
- **Bedrock**: Model-specific throughput limits

### Performance Optimizations
- **Lambda Cold Start**: Provisioned concurrency for production
- **Vector Search**: Optimized index configuration
- **Caching**: CloudFront for static content
- **Connection Pooling**: Reuse of external service connections

## Monitoring and Observability

### CloudWatch Metrics
- Lambda function duration, errors, invocations
- API Gateway request count, latency, errors
- Custom business metrics (questions processed, accuracy)

### Logging Strategy
- **Structured Logging**: JSON format with correlation IDs
- **Log Levels**: DEBUG (dev), INFO (staging/prod)
- **Retention**: 30 days for cost optimization

### Alerting
- Error rate thresholds
- Response time degradation
- Service availability monitoring

## Cost Optimization

### AWS Services Cost Structure
- **Lambda**: Pay-per-request + duration
- **API Gateway**: Pay-per-request
- **S3**: Storage + requests
- **Bedrock**: Pay-per-token
- **CloudWatch**: Logs storage + API calls

### Cost Control Measures
- Lambda timeout optimization
- S3 lifecycle policies
- CloudWatch log retention policies
- Pinecone index size monitoring

## Disaster Recovery

### Backup Strategy
- **S3**: Cross-region replication for critical documents
- **Pinecone**: Regular index backups
- **User Data**: Automated S3 versioning

### Recovery Procedures
- **RTO**: 4 hours (infrastructure recreation)
- **RPO**: 1 hour (data loss tolerance)
- **Multi-Region**: Future consideration for high availability

## Future Enhancements

### Planned Improvements
1. **Caching Layer**: Redis for frequently accessed data
2. **CDN Integration**: CloudFront for global distribution
3. **Advanced Analytics**: Real-time usage dashboards
4. **Multi-Model Support**: Additional LLM providers
5. **Stream Processing**: Real-time document processing

### Scalability Roadmap
1. **Microservices**: Break down into specialized services
2. **Event-Driven**: Move to EventBridge for loose coupling
3. **Container Support**: ECS/Fargate for complex workloads
4. **Global Distribution**: Multi-region deployment