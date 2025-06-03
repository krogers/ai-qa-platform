import { UserHistoryService, ConversationHistory } from '@/types';
import { S3Service } from '@/services/s3';
import { logger } from '@/utils/logger';

export class S3UserHistoryService implements UserHistoryService {
  private s3Service: S3Service;

  constructor() {
    this.s3Service = new S3Service();
  }

  async getUserHistory(userId: string): Promise<ConversationHistory> {
    try {
      logger.info('Fetching user history from S3', { userId });

      const historyData = await this.s3Service.getUserData(userId);

      if (!historyData || !historyData.conversationHistory) {
        return {
          userId,
          messages: [],
        };
      }

      const history = historyData.conversationHistory;
      logger.info('Retrieved user history from S3', { userId, messageCount: history.messages?.length || 0 });

      return {
        userId,
        messages: history.messages || [],
      };

    } catch (error) {
      logger.error('Error fetching user history from S3', { error, userId });
      return {
        userId,
        messages: [],
      };
    }
  }

  async saveUserInteraction(userId: string, message: string, role: 'user' | 'assistant'): Promise<void> {
    try {
      logger.info('Saving user interaction to S3', { userId, role });

      const currentHistory = await this.getUserHistory(userId);
      
      const newMessage = {
        role,
        content: message,
        timestamp: new Date(),
      };

      const updatedMessages = [...currentHistory.messages, newMessage];
      
      const maxMessages = 50;
      if (updatedMessages.length > maxMessages) {
        updatedMessages.splice(0, updatedMessages.length - maxMessages);
      }

      const userData = {
        conversationHistory: {
          userId,
          messages: updatedMessages,
        },
        lastUpdated: new Date().toISOString(),
      };

      await this.s3Service.storeUserData(userId, userData);
      logger.info('Successfully saved user interaction to S3', { userId, role });

    } catch (error) {
      logger.error('Error saving user interaction to S3', { error, userId, role });
    }
  }

  async clearUserHistory(userId: string): Promise<void> {
    try {
      logger.info('Clearing user history', { userId });

      const userData = {
        conversationHistory: {
          userId,
          messages: [],
        },
        lastUpdated: new Date().toISOString(),
      };

      await this.s3Service.storeUserData(userId, userData);
      logger.info('Successfully cleared user history', { userId });

    } catch (error) {
      logger.error('Error clearing user history', { error, userId });
      throw error;
    }
  }
}