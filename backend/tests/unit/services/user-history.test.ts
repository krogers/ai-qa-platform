import { S3UserHistoryService } from '@/services/user-history';
import { S3Service } from '@/services/s3';

jest.mock('@/services/s3');

const mockS3Service = {
  getUserData: jest.fn(),
  storeUserData: jest.fn(),
};

(S3Service as jest.Mock).mockImplementation(() => mockS3Service);

describe('S3UserHistoryService', () => {
  let userHistoryService: S3UserHistoryService;

  beforeEach(() => {
    userHistoryService = new S3UserHistoryService();
    jest.clearAllMocks();
  });

  describe('getUserHistory', () => {
    it('should fetch user history successfully', async () => {
      const mockHistoryData = {
        conversationHistory: {
          userId: 'user-123',
          messages: [
            { role: 'user', content: 'Hello', timestamp: new Date() },
            { role: 'assistant', content: 'Hi there!', timestamp: new Date() }
          ]
        }
      };

      mockS3Service.getUserData.mockResolvedValue(mockHistoryData);

      const result = await userHistoryService.getUserHistory('user-123');

      expect(result.userId).toBe('user-123');
      expect(result.messages).toEqual(mockHistoryData.conversationHistory.messages);
      expect(mockS3Service.getUserData).toHaveBeenCalledWith('user-123');
    });

    it('should return empty history when user not found', async () => {
      mockS3Service.getUserData.mockResolvedValue(null);

      const result = await userHistoryService.getUserHistory('user-123');

      expect(result.userId).toBe('user-123');
      expect(result.messages).toEqual([]);
    });

    it('should handle S3 service errors gracefully', async () => {
      mockS3Service.getUserData.mockRejectedValue(new Error('S3 error'));

      const result = await userHistoryService.getUserHistory('user-123');

      expect(result.userId).toBe('user-123');
      expect(result.messages).toEqual([]);
    });
  });

  describe('saveUserInteraction', () => {
    it('should save user interaction successfully', async () => {
      const existingHistory = {
        conversationHistory: {
          userId: 'user-123',
          messages: [
            { role: 'user', content: 'Previous message', timestamp: new Date() }
          ]
        }
      };

      mockS3Service.getUserData.mockResolvedValue(existingHistory);
      mockS3Service.storeUserData.mockResolvedValue(undefined);

      await userHistoryService.saveUserInteraction('user-123', 'Hello world', 'user');

      expect(mockS3Service.storeUserData).toHaveBeenCalledWith(
        'user-123',
        expect.objectContaining({
          conversationHistory: expect.objectContaining({
            userId: 'user-123',
            messages: expect.arrayContaining([
              expect.objectContaining({ content: 'Hello world', role: 'user' })
            ])
          })
        })
      );
    });

    it('should handle save errors gracefully', async () => {
      mockS3Service.getUserData.mockResolvedValue(null);
      mockS3Service.storeUserData.mockRejectedValue(new Error('S3 error'));

      await expect(
        userHistoryService.saveUserInteraction('user-123', 'Hello', 'user')
      ).resolves.not.toThrow();
    });

    it('should limit message history to 50 messages', async () => {
      const existingMessages = Array.from({ length: 50 }, (_, i) => ({
        role: 'user',
        content: `Message ${i}`,
        timestamp: new Date()
      }));

      const existingHistory = {
        conversationHistory: {
          userId: 'user-123',
          messages: existingMessages
        }
      };

      mockS3Service.getUserData.mockResolvedValue(existingHistory);
      mockS3Service.storeUserData.mockResolvedValue(undefined);

      await userHistoryService.saveUserInteraction('user-123', 'New message', 'user');

      const storedData = mockS3Service.storeUserData.mock.calls[0][1];
      expect(storedData.conversationHistory.messages).toHaveLength(50);
      expect(storedData.conversationHistory.messages[49].content).toBe('New message');
    });
  });
});