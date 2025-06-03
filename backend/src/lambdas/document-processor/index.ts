import { S3Handler } from 'aws-lambda';
import { S3Service } from '@/services/s3';
import { BedrockService } from '@/services/bedrock';
import { validateConfig } from '@/config';
import { logger } from '@/utils/logger';
import { v4 as uuidv4 } from 'uuid';

validateConfig();

export const handler: S3Handler = async (event) => {
  const s3Service = new S3Service();
  const bedrockService = new BedrockService();

  for (const record of event.Records) {
    const bucket = record.s3.bucket.name;
    const key = record.s3.object.key;
    const eventName = record.eventName;

    logger.info('Processing S3 event', { bucket, key, eventName });

    try {
      if (eventName.startsWith('ObjectCreated')) {
        await processNewDocument(s3Service, bedrockService, key);
      } else if (eventName.startsWith('ObjectRemoved')) {
        await processRemovedDocument(key);
      }
    } catch (error) {
      logger.error('Error processing S3 event', { error, bucket, key, eventName });
      throw error;
    }
  }
};

async function processNewDocument(
  s3Service: S3Service,
  bedrockService: BedrockService,
  key: string
): Promise<void> {
  logger.info('Processing new document', { key });

  const content = await s3Service.getDocument(key);
  if (!content) {
    logger.warn('Document content is empty', { key });
    return;
  }

  logger.info('Document processed - Bedrock Knowledge Base will automatically index it', { 
    key, 
    contentLength: content.length 
  });
  
  // Note: With Bedrock Knowledge Base, documents are automatically indexed
  // when uploaded to the S3 bucket. No manual chunking or embedding generation
  // is required. The Knowledge Base handles this automatically.
}

async function processRemovedDocument(
  key: string
): Promise<void> {
  logger.info('Processing removed document', { key });

  // Note: With Bedrock Knowledge Base, document removal is handled automatically
  // when the document is removed from the S3 bucket. The Knowledge Base will
  // automatically remove the document from the index during the next sync.
  
  logger.info('Document removal logged - Bedrock Knowledge Base will handle cleanup', { key });
}

function chunkText(text: string, chunkSize: number, overlap: number): string[] {
  const chunks: string[] = [];
  let start = 0;

  while (start < text.length) {
    const end = Math.min(start + chunkSize, text.length);
    let chunk = text.slice(start, end);

    if (end < text.length) {
      const lastPeriod = chunk.lastIndexOf('.');
      const lastNewline = chunk.lastIndexOf('\n');
      const lastSpace = chunk.lastIndexOf(' ');

      const cutPoint = Math.max(lastPeriod, lastNewline, lastSpace);
      if (cutPoint > start + chunkSize * 0.5) {
        chunk = text.slice(start, cutPoint + 1);
        start = cutPoint + 1 - overlap;
      } else {
        start = end - overlap;
      }
    } else {
      start = end;
    }

    if (chunk.trim()) {
      chunks.push(chunk.trim());
    }
  }

  return chunks;
}