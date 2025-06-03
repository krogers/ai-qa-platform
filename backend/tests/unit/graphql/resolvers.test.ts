import { mutationResolvers } from '@/graphql/resolvers/mutation-resolvers';
import { queryResolvers } from '@/graphql/resolvers/query-resolvers';
import { ValidationError } from '@/utils/errors';

jest.mock('@/services/s3');
jest.mock('@/services/bedrock');
jest.mock('@/services/user-history');

const mockS3Service = {
  getFallbackContext: jest.fn(),
};

const mockBedrockService = {
  generateResponse: jest.fn(),
  search: jest.fn(),
};

const mockUserHistoryService = {
  getUserHistory: jest.fn(),
  saveUserInteraction: jest.fn(),
};


jest.mock('@/services/s3', () => ({
  S3Service: jest.fn().mockImplementation(() => mockS3Service)
}));

jest.mock('@/services/bedrock', () => ({
  BedrockService: jest.fn().mockImplementation(() => mockBedrockService)
}));

jest.mock('@/services/user-history', () => ({
  S3UserHistoryService: jest.fn().mockImplementation(() => mockUserHistoryService)
}));

describe('GraphQL Resolvers', () => {
  const mockContext = {
    requestId: 'test-request-id',
    userId: 'test-user-id'
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Query Resolvers', () => {
    describe('health', () => {
      it('should return OK', () => {
        const result = queryResolvers.health();
        expect(result).toBe('OK');
      });
    });

    describe('getUserHistory', () => {
      it('should fetch user history', async () => {
        const mockHistory = {
          userId: 'test-user',
          messages: []
        };

        mockUserHistoryService.getUserHistory.mockResolvedValue(mockHistory);

        const result = await queryResolvers.getUserHistory(
          {},
          { userId: 'test-user' },
          mockContext
        );

        expect(result).toEqual(mockHistory);
        expect(mockUserHistoryService.getUserHistory).toHaveBeenCalledWith('test-user');
      });
    });

    describe('searchDocuments', () => {
      it('should search documents using Bedrock Knowledge Base', async () => {
        const mockChunks = [
          { id: '1', content: 'test content', metadata: {}, score: 0.9 }
        ];

        mockBedrockService.search.mockResolvedValue(mockChunks);

        const result = await queryResolvers.searchDocuments(
          {},
          { query: 'test query', topK: 5 },
          mockContext
        );

        expect(result).toEqual(mockChunks);
        expect(mockBedrockService.search).toHaveBeenCalledWith('test query', 5);
      });
    });
  });

  describe('Mutation Resolvers', () => {
    describe('askQuestion', () => {
      const validInput = {
        text: 'What is AI?',
        userId: 'test-user-id'
      };

      beforeEach(() => {
        mockBedrockService.search.mockResolvedValue([
          { id: '1', content: 'AI is artificial intelligence', metadata: { source: 'doc1' }, score: 0.9 }
        ]);
        mockS3Service.getFallbackContext.mockResolvedValue('Fallback context');
        mockBedrockService.generateResponse.mockResolvedValue('AI is a fascinating field...');
        mockUserHistoryService.getUserHistory.mockResolvedValue({ userId: 'test-user-id', messages: [] });
        mockUserHistoryService.saveUserInteraction.mockResolvedValue(undefined);
      });

      it('should process question successfully with vector search results', async () => {
        const result = await mutationResolvers.askQuestion(
          {},
          { input: validInput },
          mockContext
        );

        expect(result).toMatchObject({
          text: 'AI is a fascinating field...',
          confidence: 0.9,
          sources: ['doc1']
        });

        expect(mockBedrockService.search).toHaveBeenCalledWith('What is AI?', 5);
        expect(mockBedrockService.generateResponse).toHaveBeenCalled();
        expect(mockUserHistoryService.saveUserInteraction).toHaveBeenCalledTimes(2);
      });

      it('should fall back to S3 context when Bedrock Knowledge Base search score is low', async () => {
        mockBedrockService.search.mockResolvedValue([
          { id: '1', content: 'Low relevance content', metadata: {}, score: 0.3 }
        ]);

        const result = await mutationResolvers.askQuestion(
          {},
          { input: validInput },
          mockContext
        );

        expect(result.confidence).toBe(0.6);
        expect(result.sources).toEqual(['fallback-knowledge-base']);
        expect(mockS3Service.getFallbackContext).toHaveBeenCalled();
      });

      it('should validate empty question text', async () => {
        await expect(
          mutationResolvers.askQuestion(
            {},
            { input: { ...validInput, text: '' } },
            mockContext
          )
        ).rejects.toThrow(ValidationError);
      });

      it('should validate question text length', async () => {
        const longText = 'a'.repeat(1001);

        await expect(
          mutationResolvers.askQuestion(
            {},
            { input: { ...validInput, text: longText } },
            mockContext
          )
        ).rejects.toThrow(ValidationError);
      });
    });
  });
});