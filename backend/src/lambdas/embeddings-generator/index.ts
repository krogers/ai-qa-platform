import { APIGatewayProxyHandler, APIGatewayProxyResult } from 'aws-lambda';
import { BedrockService } from '@/services/bedrock';
import { validateConfig } from '@/config';
import { logger } from '@/utils/logger';
import { ValidationError } from '@/utils/errors';
import { v4 as uuidv4 } from 'uuid';

validateConfig();

interface EmbeddingRequest {
  text: string;
  metadata?: Record<string, any>;
}

interface EmbeddingResponse {
  id: string;
  embedding: number[];
  metadata?: Record<string, any>;
}

export const handler: APIGatewayProxyHandler = async (event): Promise<APIGatewayProxyResult> => {
  const requestId = uuidv4();
  
  try {
    logger.info('Processing embedding request', { requestId });

    if (!event.body) {
      throw new ValidationError('Request body is required');
    }

    const request: EmbeddingRequest = JSON.parse(event.body);

    if (!request.text || typeof request.text !== 'string') {
      throw new ValidationError('Text field is required and must be a string');
    }

    if (request.text.length > 10000) {
      throw new ValidationError('Text cannot exceed 10,000 characters');
    }

    const bedrockService = new BedrockService();

    logger.info('Generating embedding', { requestId, textLength: request.text.length });
    const embedding = await bedrockService.generateEmbedding(request.text);

    const vectorId = uuidv4();
    const metadata = {
      ...request.metadata,
      timestamp: new Date().toISOString(),
      textLength: request.text.length,
    };

    logger.info('Embedding generated successfully', { requestId, vectorId });
    // Note: Bedrock Knowledge Base handles vector storage automatically
    // This endpoint now only generates embeddings for testing/debugging

    const response: EmbeddingResponse = {
      id: vectorId,
      embedding,
      metadata,
    };

    logger.info('Successfully processed embedding request', { requestId, vectorId });

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
      body: JSON.stringify(response),
    } as APIGatewayProxyResult;

  } catch (error) {
    logger.error('Error processing embedding request', { error, requestId });

    if (error instanceof ValidationError) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({
          error: error.message,
          requestId,
        }),
      } as APIGatewayProxyResult;
    }

    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Internal server error',
        requestId,
      }),
    } as APIGatewayProxyResult;
  }
};