import type { FastifyInstance } from 'fastify';
import { ZodError } from 'zod';
import { AppError } from '../shared/errors.js';

export async function errorHandlerPlugin(app: FastifyInstance) {
  app.setErrorHandler((error, _request, reply) => {
    // Handle Zod validation errors
    if (error instanceof ZodError) {
      return reply.status(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Request validation failed',
          details: error.flatten().fieldErrors,
        },
      });
    }

    // Handle known application errors
    if (error instanceof AppError) {
      return reply.status(error.statusCode).send({
        error: {
          code: error.code,
          message: error.message,
          ...(error.details !== undefined && { details: error.details }),
        },
      });
    }

    // Handle Fastify validation errors (schema validation)
    if (error.statusCode === 400) {
      return reply.status(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: error.message,
        },
      });
    }

    // Unhandled errors — log and return 500
    app.log.error({ err: error }, 'Unhandled error');

    return reply.status(500).send({
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'An unexpected error occurred',
      },
    });
  });
}
