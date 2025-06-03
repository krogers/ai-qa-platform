import winston from 'winston';
import { config } from '@/config';

const logger = winston.createLogger({
  level: config.environment === 'prod' ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'ai-qa-platform' },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ],
});

if (config.environment === 'prod') {
  logger.add(new winston.transports.Console({
    format: winston.format.json()
  }));
}

export { logger };