import { ConversationHistory, DocumentChunk } from '@/types';
import { S3UserHistoryService } from '@/services/user-history';
import { BedrockService } from '@/services/bedrock';
import { logger } from '@/utils/logger';
import { v4 as uuidv4 } from 'uuid';

export const queryResolvers = {
  getUserHistory: async (
    _: any,
    { userId }: { userId: string }
  ): Promise<ConversationHistory> => {
    const requestId = uuidv4();
    logger.info('Fetching user history', { userId, requestId });

    const userHistoryService = new S3UserHistoryService();
    return await userHistoryService.getUserHistory(userId);
  },

  searchDocuments: async (
    _: any,
    { query, topK }: { query: string; topK: number }
  ): Promise<DocumentChunk[]> => {
    const requestId = uuidv4();
    logger.info('Searching documents', { query: query.substring(0, 100), topK, requestId });

    const bedrockService = new BedrockService();
    return await bedrockService.search(query, topK);
  },

  health: (): string => {
    return 'OK';
  },
};