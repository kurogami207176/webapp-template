import type { FastifyInstance } from 'fastify';
import { UnauthorizedError } from '../shared/errors.js';

export async function authPlugin(app: FastifyInstance) {
  app.decorateRequest('user', null);

  // Decorator to protect routes — add `preHandler: [app.authenticate]` to routes
  app.decorate('authenticate', async (request: Parameters<typeof app.authenticate>[0]) => {
    try {
      const payload = await request.jwtVerify<{ sub: string; email: string }>();
      request.user = { id: payload.sub, email: payload.email };
    } catch {
      throw new UnauthorizedError('Invalid or expired token');
    }
  });
}

// Augment Fastify to include the `authenticate` decorator
declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (request: import('fastify').FastifyRequest) => Promise<void>;
  }
}
