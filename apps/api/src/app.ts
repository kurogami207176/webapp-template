import Fastify from 'fastify';
import fastifyCors from '@fastify/cors';
import fastifyJwt from '@fastify/jwt';
import fastifyRateLimit from '@fastify/rate-limit';
import { config } from './config/index.js';
import { loggerConfig } from './config/logger.js';
import { errorHandlerPlugin } from './plugins/error-handler.plugin.js';
import { authPlugin } from './plugins/auth.plugin.js';
import { healthRoutes } from './modules/health/health.routes.js';
import { authRoutes } from './modules/auth/auth.routes.js';
import { usersRoutes } from './modules/users/users.routes.js';

export async function buildApp() {
  const app = Fastify({ logger: loggerConfig });

  // Core plugins
  await app.register(fastifyCors, { origin: config.CORS_ORIGIN });
  await app.register(fastifyJwt, { secret: config.JWT_SECRET });
  await app.register(fastifyRateLimit, {
    max: 100,
    timeWindow: '1 minute',
  });

  // Application plugins
  await app.register(errorHandlerPlugin);
  await app.register(authPlugin);

  // Routes
  await app.register(healthRoutes);
  await app.register(authRoutes, { prefix: '/api/v1/auth' });
  await app.register(usersRoutes, { prefix: '/api/v1/users' });

  return app;
}
