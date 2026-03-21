import type { FastifyBaseLogger } from 'fastify';
import type { PinoLoggerOptions } from 'fastify/types/logger.js';
import { config } from './index.js';

const isProduction = config.NODE_ENV === 'production';

export const loggerConfig: PinoLoggerOptions | FastifyBaseLogger = isProduction
  ? {
      level: config.LOG_LEVEL,
    }
  : {
      level: config.LOG_LEVEL,
      transport: {
        target: 'pino-pretty',
        options: {
          translateTime: 'HH:MM:ss Z',
          ignore: 'pid,hostname',
        },
      },
    };
