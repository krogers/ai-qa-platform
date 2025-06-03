import { S3Client, GetObjectCommand, PutObjectCommand, ListObjectsV2Command } from '@aws-sdk/client-s3';
import { DocumentService } from '@/types';
import { config } from '@/config';
import { logger } from '@/utils/logger';
import { ServiceUnavailableError, NotFoundError } from '@/utils/errors';

export class S3Service implements DocumentService {
  private client: S3Client;

  constructor() {
    this.client = new S3Client({
      region: config.bedrock.region,
    });
  }

  async getFallbackContext(topic: string): Promise<string> {
    try {
      logger.info('Searching for fallback context', { topic });

      const listCommand = new ListObjectsV2Command({
        Bucket: config.s3.knowledgeBucket,
        Prefix: 'fallback/',
        MaxKeys: 10,
      });

      const listResponse = await this.client.send(listCommand);

      if (!listResponse.Contents || listResponse.Contents.length === 0) {
        logger.warn('No fallback documents found');
        return 'No additional context available for this topic.';
      }

      const contextPromises = listResponse.Contents.slice(0, 3).map(async (object) => {
        if (object.Key) {
          return this.getDocument(object.Key);
        }
        return null;
      });

      const contexts = await Promise.all(contextPromises);
      const validContexts = contexts.filter(Boolean) as string[];

      return validContexts.join('\n\n') || 'No additional context available for this topic.';

    } catch (error) {
      logger.error('Error retrieving fallback context', { error, topic });
      return 'No additional context available for this topic.';
    }
  }

  async getDocument(key: string): Promise<string | null> {
    try {
      const command = new GetObjectCommand({
        Bucket: config.s3.knowledgeBucket,
        Key: key,
      });

      const response = await this.client.send(command);

      if (!response.Body) {
        return null;
      }

      const content = await response.Body.transformToString();
      logger.info('Retrieved document from S3', { key, size: content.length });

      return content;

    } catch (error: any) {
      if (error.name === 'NoSuchKey') {
        logger.warn('Document not found in S3', { key });
        return null;
      }

      logger.error('Error retrieving document from S3', { error, key });
      throw new ServiceUnavailableError('S3');
    }
  }

  async storeDocument(key: string, content: string, metadata?: Record<string, any>): Promise<void> {
    try {
      const command = new PutObjectCommand({
        Bucket: config.s3.knowledgeBucket,
        Key: key,
        Body: content,
        ContentType: 'text/plain',
        Metadata: metadata ? Object.fromEntries(
          Object.entries(metadata).map(([k, v]) => [k, String(v)])
        ) : undefined,
      });

      await this.client.send(command);
      logger.info('Stored document in S3', { key, size: content.length });

    } catch (error) {
      logger.error('Error storing document in S3', { error, key });
      throw new ServiceUnavailableError('S3');
    }
  }

  async storeUserData(userId: string, data: Record<string, any>): Promise<void> {
    try {
      const key = `users/${userId}/data.json`;
      const content = JSON.stringify(data, null, 2);

      const command = new PutObjectCommand({
        Bucket: config.s3.userDataBucket,
        Key: key,
        Body: content,
        ContentType: 'application/json',
      });

      await this.client.send(command);
      logger.info('Stored user data in S3', { userId, key });

    } catch (error) {
      logger.error('Error storing user data in S3', { error, userId });
      throw new ServiceUnavailableError('S3');
    }
  }

  async getUserData(userId: string): Promise<Record<string, any> | null> {
    try {
      const key = `users/${userId}/data.json`;
      const content = await this.getDocument(key);

      if (!content) {
        return null;
      }

      return JSON.parse(content);

    } catch (error) {
      logger.error('Error retrieving user data from S3', { error, userId });
      return null;
    }
  }
}