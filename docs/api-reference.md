# AI Q&A Platform - API Reference

## GraphQL Endpoint

**URL**: `https://your-api-gateway-url/{environment}/graphql`  
**Method**: `POST`  
**Content-Type**: `application/json`

**Note**: The system includes a responsive SPA frontend at `frontend/index.html` that provides an elegant user interface for interacting with this API.

## Authentication

Include the user ID in the request headers:
```
X-User-Id: {uuid}
```

**Note**: The frontend SPA automatically handles user ID generation and includes it in API requests.

## GraphQL Schema

### Types

#### Question
```graphql
type Question {
  id: UUID!
  text: String!
  userId: UUID!
  timestamp: Date!
}
```

#### Answer
```graphql
type Answer {
  id: UUID!
  questionId: UUID!
  text: String!
  confidence: Float!
  sources: [String!]!
  timestamp: Date!
}
```

#### DocumentChunk
```graphql
type DocumentChunk {
  id: String!
  content: String!
  metadata: JSON!
  score: Float
}
```

#### ConversationHistory
```graphql
type ConversationHistory {
  userId: UUID!
  messages: [ConversationMessage!]!
}

type ConversationMessage {
  role: MessageRole!
  content: String!
  timestamp: Date!
}

enum MessageRole {
  USER
  ASSISTANT
}
```

### Queries

#### health
```graphql
query {
  health
}
```
**Returns**: `String!` - "OK" if service is healthy

#### getUserHistory
```graphql
query getUserHistory($userId: UUID!) {
  getUserHistory(userId: $userId) {
    userId
    messages {
      role
      content
      timestamp
    }
  }
}
```

**Parameters**:
- `userId`: UUID of the user

**Returns**: `ConversationHistory!`

#### searchDocuments
```graphql
query searchDocuments($query: String!, $topK: Int) {
  searchDocuments(query: $query, topK: $topK) {
    id
    content
    metadata
    score
  }
}
```

**Parameters**:
- `query`: Search query string
- `topK`: Number of results to return (default: 5)

**Returns**: `[DocumentChunk!]!`

### Mutations

#### askQuestion
```graphql
mutation askQuestion($input: QuestionInput!) {
  askQuestion(input: $input) {
    id
    questionId
    text
    confidence
    sources
    timestamp
  }
}
```

**Input Type**:
```graphql
input QuestionInput {
  text: String!
  userId: UUID!
}
```

**Parameters**:
- `text`: Question text (max 1000 characters)
- `userId`: UUID of the user asking the question

**Returns**: `Answer!`

## Example Requests

### Submit a Question

#### Via Frontend SPA
Open `frontend/index.html` in a browser and use the elegant chat interface to ask questions.

#### Via API
```bash
curl -X POST https://your-api-gateway-url/dev/graphql \
  -H 'Content-Type: application/json' \
  -H 'X-User-Id: 550e8400-e29b-41d4-a716-446655440000' \
  -d '{
    "query": "mutation askQuestion($input: QuestionInput!) { askQuestion(input: $input) { id text confidence sources timestamp } }",
    "variables": {
      "input": {
        "text": "Tell me about Kevin Rogers",
        "userId": "550e8400-e29b-41d4-a716-446655440000"
      }
    }
  }'
```

**Response**:
```json
{
  "data": {
    "askQuestion": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "text": "Kevin Rogers is a seasoned professional with expertise in...",
      "confidence": 0.9,
      "sources": ["document-1.pdf", "document-2.txt"],
      "timestamp": "2023-12-01T10:30:00Z"
    }
  }
}
```

### Get User History
```bash
curl -X POST https://your-api-gateway-url/dev/graphql \
  -H 'Content-Type: application/json' \
  -H 'X-User-Id: 550e8400-e29b-41d4-a716-446655440000' \
  -d '{
    "query": "query getUserHistory($userId: UUID!) { getUserHistory(userId: $userId) { userId messages { role content timestamp } } }",
    "variables": {
      "userId": "550e8400-e29b-41d4-a716-446655440000"
    }
  }'
```

**Response**:
```json
{
  "data": {
    "getUserHistory": {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "messages": [
        {
          "role": "USER",
          "content": "What is AI?",
          "timestamp": "2023-12-01T10:29:00Z"
        },
        {
          "role": "ASSISTANT",
          "content": "Artificial intelligence refers to...",
          "timestamp": "2023-12-01T10:30:00Z"
        }
      ]
    }
  }
}
```

### Search Documents
```bash
curl -X POST https://your-api-gateway-url/dev/graphql \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "query searchDocuments($query: String!, $topK: Int) { searchDocuments(query: $query, topK: $topK) { id content score metadata } }",
    "variables": {
      "query": "machine learning",
      "topK": 3
    }
  }'
```

**Response**:
```json
{
  "data": {
    "searchDocuments": [
      {
        "id": "doc1#0",
        "content": "Machine learning is a subset of artificial intelligence...",
        "score": 0.95,
        "metadata": {
          "source": "ml-handbook.pdf",
          "chunkIndex": 0
        }
      }
    ]
  }
}
```

## Error Handling

### Error Response Format
```json
{
  "errors": [
    {
      "message": "Question text cannot be empty",
      "code": 400,
      "path": ["askQuestion"]
    }
  ],
  "data": null
}
```

### Common Error Codes
- `400`: Validation Error (invalid input)
- `404`: Resource Not Found
- `429`: Rate Limit Exceeded
- `500`: Internal Server Error
- `503`: Service Unavailable

### Validation Rules

#### askQuestion Input
- `text`: Required, 1-1000 characters
- `userId`: Required, valid UUID format

#### searchDocuments Input
- `query`: Required, non-empty string
- `topK`: Optional, integer 1-50 (default: 5)

#### getUserHistory Input
- `userId`: Required, valid UUID format

## Rate Limits

- **API Gateway**: 10,000 requests per second (configurable)
- **Lambda**: Concurrent execution limits apply
- **Bedrock**: Model-specific rate limits apply
- **Bedrock Knowledge Base**: Query-based rate limits apply

## Response Times

- **Health Check**: < 100ms
- **Search Documents**: 200-500ms
- **Ask Question**: 2-10 seconds (depending on context processing and Bedrock Knowledge Base retrieval)
- **Get User History**: 100-300ms

## Best Practices

1. **Include User ID**: Always provide `X-User-Id` header for personalized responses
2. **Error Handling**: Implement retry logic for 5xx errors
3. **Caching**: Consider caching frequent queries on the client side
4. **Timeouts**: Set appropriate timeouts (30s recommended for askQuestion)
5. **Validation**: Validate inputs on the client side before sending requests
6. **Frontend Usage**: Use the provided SPA for optimal user experience with built-in responsive design
7. **Content Focus**: Questions should relate to Kevin Rogers or system functionality as configured in system prompts