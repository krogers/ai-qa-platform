import { z } from 'zod';

export const QuestionSchema = z.object({
  id: z.string().uuid(),
  text: z.string().min(1).max(1000),
  userId: z.string().uuid(),
  timestamp: z.date(),
});

// Internal answer type with all fields for logging
export const InternalAnswerSchema = z.object({
  id: z.string().uuid(),
  questionId: z.string().uuid(),
  text: z.string().min(1),
  confidence: z.number().min(0).max(1),
  sources: z.array(z.string()),
  timestamp: z.date(),
});

// Client-facing answer type without sensitive fields
export const AnswerSchema = z.object({
  id: z.string().uuid(),
  questionId: z.string().uuid(),
  text: z.string().min(1),
  timestamp: z.date(),
});

export const DocumentChunkSchema = z.object({
  id: z.string(),
  content: z.string(),
  metadata: z.record(z.any()),
  score: z.number().optional(),
});

export const ConversationHistorySchema = z.object({
  userId: z.string().uuid(),
  messages: z.array(z.object({
    role: z.enum(['user', 'assistant']),
    content: z.string(),
    timestamp: z.date(),
  })),
});

export const GraphQLContextSchema = z.object({
  userId: z.string().uuid().optional(),
  requestId: z.string().uuid().optional(),
});

export type Question = z.infer<typeof QuestionSchema>;
export type InternalAnswer = z.infer<typeof InternalAnswerSchema>;
export type Answer = z.infer<typeof AnswerSchema>;
export type DocumentChunk = z.infer<typeof DocumentChunkSchema>;
export type ConversationHistory = z.infer<typeof ConversationHistorySchema>;
export type GraphQLContext = z.infer<typeof GraphQLContextSchema>;

export interface VectorSearchService {
  search(query: string, topK: number): Promise<DocumentChunk[]>;
  upsert(vectors: Array<{ id: string; values: number[]; metadata: Record<string, any> }>): Promise<void>;
}

export interface DocumentService {
  getFallbackContext(topic: string): Promise<string>;
  storeDocument(key: string, content: string, metadata?: Record<string, any>): Promise<void>;
  getDocument(key: string): Promise<string | null>;
}

export interface UserHistoryService {
  getUserHistory(userId: string): Promise<ConversationHistory>;
  saveUserInteraction(userId: string, message: string, role: 'user' | 'assistant'): Promise<void>;
}

export interface LLMService {
  generateResponse(prompt: string, context: string, history?: ConversationHistory): Promise<string>;
  generateEmbedding(text: string): Promise<number[]>;
}

export interface Config {
  bedrock: {
    region: string;
    modelId: string;
    knowledgeBaseId: string;
  };
  s3: {
    knowledgeBucket: string;
    userDataBucket: string;
  };
  environment: 'dev' | 'staging' | 'prod';
}