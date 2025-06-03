import { BedrockService } from '@/services/bedrock';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { ServiceUnavailableError } from '@/utils/errors';

jest.mock('@aws-sdk/client-bedrock-runtime');

const mockSend = jest.fn();
const mockBedrockClient = {
  send: mockSend,
};

(BedrockRuntimeClient as jest.Mock).mockImplementation(() => mockBedrockClient);

describe('BedrockService', () => {
  let bedrockService: BedrockService;

  beforeEach(() => {
    bedrockService = new BedrockService();
    jest.clearAllMocks();
  });

  describe('generateResponse', () => {
    it('should generate a response successfully', async () => {
      const mockResponse = {
        body: new TextEncoder().encode(JSON.stringify({
          content: [{ text: 'This is a test response' }]
        }))
      };

      mockSend.mockResolvedValue(mockResponse);

      const result = await bedrockService.generateResponse(
        'What is AI?',
        'AI stands for Artificial Intelligence'
      );

      expect(result).toBe('This is a test response');
      expect(mockSend).toHaveBeenCalledWith(expect.any(InvokeModelCommand));
    });

    it('should handle invalid response format', async () => {
      const mockResponse = {
        body: new TextEncoder().encode(JSON.stringify({}))
      };

      mockSend.mockResolvedValue(mockResponse);

      await expect(
        bedrockService.generateResponse('What is AI?', 'Context')
      ).rejects.toThrow(ServiceUnavailableError);
    });

    it('should handle Bedrock service errors', async () => {
      mockSend.mockRejectedValue(new Error('Bedrock service error'));

      await expect(
        bedrockService.generateResponse('What is AI?', 'Context')
      ).rejects.toThrow(ServiceUnavailableError);
    });
  });

  describe('generateEmbedding', () => {
    it('should generate embedding successfully', async () => {
      const mockEmbedding = [0.1, 0.2, 0.3];
      const mockResponse = {
        body: new TextEncoder().encode(JSON.stringify({
          embedding: mockEmbedding
        }))
      };

      mockSend.mockResolvedValue(mockResponse);

      const result = await bedrockService.generateEmbedding('test text');

      expect(result).toEqual(mockEmbedding);
      expect(mockSend).toHaveBeenCalledWith(expect.any(InvokeModelCommand));
    });

    it('should handle embedding service errors', async () => {
      mockSend.mockRejectedValue(new Error('Embedding service error'));

      await expect(
        bedrockService.generateEmbedding('test text')
      ).rejects.toThrow(ServiceUnavailableError);
    });
  });
});