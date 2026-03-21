import type { FastifyInstance } from 'fastify';
import { AuthService } from './auth.service.js';
import {
  LoginBodySchema,
  RefreshBodySchema,
  RegisterBodySchema,
} from './auth.schema.js';

export async function authRoutes(app: FastifyInstance) {
  const authService = new AuthService(app);

  app.post('/register', {
    schema: { body: RegisterBodySchema },
    handler: async (request, reply) => {
      const result = await authService.register(request.body);
      return reply.status(201).send(result);
    },
  });

  app.post('/login', {
    schema: { body: LoginBodySchema },
    handler: async (request, reply) => {
      const result = await authService.login(request.body);
      return reply.send(result);
    },
  });

  app.post('/refresh', {
    schema: { body: RefreshBodySchema },
    handler: async (request, reply) => {
      const result = await authService.refresh(request.body.refreshToken);
      return reply.send(result);
    },
  });

  app.post('/logout', {
    preHandler: [app.authenticate],
    schema: { body: RefreshBodySchema },
    handler: async (request, reply) => {
      await authService.logout(request.body.refreshToken);
      return reply.status(204).send();
    },
  });
}
