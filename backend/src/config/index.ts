import { Config } from '@/types';

export const config: Config = {
  bedrock: {
    region: process.env.BEDROCK_REGION || 'us-east-1',
    modelId: process.env.BEDROCK_MODEL_ID || 'us.anthropic.claude-3-7-sonnet-20250219-v1:0', // Claude 3.7 Sonnet inference profile
    knowledgeBaseId: process.env.BEDROCK_KNOWLEDGE_BASE_ID || 'TWUGXOGLL7',
  },
  s3: {
    knowledgeBucket: process.env.S3_KNOWLEDGE_BUCKET || '',
    userDataBucket: process.env.S3_USER_DATA_BUCKET || '',
  },
  environment: (process.env.NODE_ENV as 'dev' | 'staging' | 'prod') || 'dev',
};

export function validateConfig(): void {
  const required = [
    'S3_KNOWLEDGE_BUCKET',
    'S3_USER_DATA_BUCKET',
  ];

  for (const envVar of required) {
    if (!process.env[envVar]) {
      throw new Error(`Missing required environment variable: ${envVar}`);
    }
  }
}