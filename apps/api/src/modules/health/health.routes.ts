import type { FastifyInstance } from 'fastify';
import { prisma } from '../../db/client.js';

export async function healthRoutes(app: FastifyInstance) {
  app.get('/health', async (_request, reply) => {
    let dbStatus = 'ok';

    try {
      await prisma.$queryRaw`SELECT 1`;
    } catch {
      dbStatus = 'error';
    }

    const status = dbStatus === 'ok' ? 'ok' : 'degraded';

    return reply.status(status === 'ok' ? 200 : 503).send({
      status,
      timestamp: new Date().toISOString(),
      services: {
        database: dbStatus,
      },
    });
  });
}
