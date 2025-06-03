process.env.NODE_ENV = 'test';
process.env.BEDROCK_REGION = 'us-east-1';
process.env.BEDROCK_MODEL_ID = 'test-model';
process.env.BEDROCK_KNOWLEDGE_BASE_ID = 'test-knowledge-base-id';
process.env.S3_KNOWLEDGE_BUCKET = 'test-knowledge-bucket';
process.env.S3_USER_DATA_BUCKET = 'test-user-data-bucket';

global.fetch = jest.fn();

afterEach(() => {
  jest.clearAllMocks();
});