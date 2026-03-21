import type { FastifyRequest } from 'fastify';

export interface AuthenticatedUser {
  id: string;
  email: string;
}

export interface JwtPayload {
  sub: string;
  email: string;
  iat: number;
  exp: number;
}

// Augment FastifyRequest to include the authenticated user
declare module 'fastify' {
  interface FastifyRequest {
    user?: AuthenticatedUser;
  }
}
