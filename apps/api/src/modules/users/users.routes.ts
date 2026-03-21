import type { FastifyInstance } from 'fastify';
import { PaginationSchema, IdParamSchema, UpdateUserBodySchema } from '@webapp/shared-types';
import { ForbiddenError } from '../../shared/errors.js';
import { UsersRepository } from './users.repository.js';
import { UsersService } from './users.service.js';

export async function usersRoutes(app: FastifyInstance) {
  const usersService = new UsersService(new UsersRepository());

  // GET /users — list all users (authenticated)
  app.get('/', {
    preHandler: [app.authenticate],
    schema: { querystring: PaginationSchema },
    handler: async (request) => {
      const { page, limit } = request.query;
      return usersService.list(page, limit);
    },
  });

  // GET /users/:id — get user by id (authenticated)
  app.get('/:id', {
    preHandler: [app.authenticate],
    schema: { params: IdParamSchema },
    handler: async (request) => {
      return usersService.getById(request.params.id);
    },
  });

  // PATCH /users/:id — update user (own profile only)
  app.patch('/:id', {
    preHandler: [app.authenticate],
    schema: { params: IdParamSchema, body: UpdateUserBodySchema },
    handler: async (request) => {
      if (request.user?.id !== request.params.id) {
        throw new ForbiddenError('You can only update your own profile');
      }
      return usersService.update(request.params.id, request.body);
    },
  });

  // DELETE /users/:id — delete user (own account only)
  app.delete('/:id', {
    preHandler: [app.authenticate],
    schema: { params: IdParamSchema },
    handler: async (request, reply) => {
      if (request.user?.id !== request.params.id) {
        throw new ForbiddenError('You can only delete your own account');
      }
      await usersService.delete(request.params.id);
      return reply.status(204).send();
    },
  });
}
