import { v4 as uuidv4 } from 'uuid';
import { Answer, InternalAnswer } from '@/types';
import { S3Service } from '@/services/s3';
import { BedrockService } from '@/services/bedrock';
import { S3UserHistoryService } from '@/services/user-history';
import { logger } from '@/utils/logger';
import { ValidationError } from '@/utils/errors';

export interface QuestionInput {
  text: string;
  userId: string;
}

export const mutationResolvers = {
  askQuestion: async (
    _: any,
    { input }: { input: QuestionInput }
  ): Promise<Answer> => {
    const { text, userId } = input;
    const questionId = uuidv4();
    const answerId = uuidv4();

    const requestId = uuidv4();
    logger.info('Processing question', { 
      questionId, 
      userId, 
      questionText: text.substring(0, 100),
      requestId 
    });

    if (!text.trim()) {
      throw new ValidationError('Question text cannot be empty');
    }

    if (text.length > 1000) {
      throw new ValidationError('Question text cannot exceed 1000 characters');
    }

    try {
      const s3Service = new S3Service();
      const bedrockService = new BedrockService();
      const userHistoryService = new S3UserHistoryService();

      logger.info('Step 1: Searching knowledge base', { questionId });
      let relevantChunks = await bedrockService.search(text, 5);

      let contextText = '';
      let sources: string[] = [];

      if (relevantChunks.length > 0 && relevantChunks[0].score && relevantChunks[0].score > 0.4) {
        contextText = relevantChunks
          .filter(chunk => chunk.score && chunk.score > 0.4)
          .map(chunk => chunk.content)
          .join('\n\n');
        
        sources = relevantChunks
          .filter(chunk => chunk.score && chunk.score > 0.4)
          .map(chunk => chunk.metadata.source || chunk.id);

        logger.info('Using knowledge base search results', { 
          questionId, 
          chunksFound: relevantChunks.length,
          relevantChunks: sources.length
        });
      } else {
        logger.info('Step 2: Falling back to S3 context', { questionId });
        contextText = await s3Service.getFallbackContext(text);
        sources = ['fallback-knowledge-base'];
      }

      logger.info('Step 3: Retrieving user history', { questionId, userId });
      const userHistory = await userHistoryService.getUserHistory(userId);

      logger.info('Step 4: Generating AI response', { questionId });
      const aiResponse = await bedrockService.generateResponse(text, contextText, userHistory);

      logger.info('Step 5: Saving user interaction', { questionId, userId });
      await Promise.all([
        userHistoryService.saveUserInteraction(userId, text, 'user'),
        userHistoryService.saveUserInteraction(userId, aiResponse, 'assistant'),
      ]);

      // Internal answer with all fields for logging
      const internalAnswer: InternalAnswer = {
        id: answerId,
        questionId,
        text: aiResponse,
        confidence: sources.length > 0 && sources[0] !== 'fallback-knowledge-base' ? 0.9 : 0.6,
        sources,
        timestamp: new Date(),
      };

      // Client-facing answer without sensitive fields
      const clientAnswer: Answer = {
        id: answerId,
        questionId,
        text: aiResponse,
        timestamp: new Date(),
      };

      logger.info('Successfully processed question', { 
        questionId, 
        answerId, 
        userId,
        responseLength: aiResponse.length,
        confidence: internalAnswer.confidence,
        sourcesCount: sources.length,
        sources: sources
      });

      return clientAnswer;

    } catch (error) {
      logger.error('Error processing question', { 
        error, 
        questionId, 
        userId,
        requestId 
      });
      throw error;
    }
  },
};