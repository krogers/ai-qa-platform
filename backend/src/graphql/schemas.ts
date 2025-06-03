export const typesSchema = `scalar Date
scalar UUID

type Question {
  id: UUID!
  text: String!
  userId: UUID!
  timestamp: Date!
}

type Answer {
  id: UUID!
  questionId: UUID!
  text: String!
  confidence: Float!
  sources: [String!]!
  timestamp: Date!
}

type DocumentChunk {
  id: String!
  content: String!
  metadata: JSON!
  score: Float
}

type ConversationMessage {
  role: MessageRole!
  content: String!
  timestamp: Date!
}

type ConversationHistory {
  userId: UUID!
  messages: [ConversationMessage!]!
}

enum MessageRole {
  USER
  ASSISTANT
}

scalar JSON`;

export const querySchema = `type Query {
  """
  Get conversation history for a user
  """
  getUserHistory(userId: UUID!): ConversationHistory!
  
  """
  Search knowledge base for relevant documents
  """
  searchDocuments(query: String!, topK: Int = 5): [DocumentChunk!]!
  
  """
  Health check endpoint
  """
  health: String!
}`;

export const mutationSchema = `input QuestionInput {
  text: String!
  userId: UUID!
}

type Mutation {
  """
  Submit a question and get an AI-generated answer
  """
  askQuestion(input: QuestionInput!): Answer!
}`;