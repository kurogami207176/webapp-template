import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import supertest from 'supertest';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../../src/app.js';
import { prisma } from '../../src/db/client.js';

let app: FastifyInstance;

beforeAll(async () => {
  app = await buildApp();
  await app.ready();
});

afterAll(async () => {
  await app.close();
  await prisma.$disconnect();
});

beforeEach(async () => {
  await prisma.session.deleteMany();
  await prisma.user.deleteMany();
});

describe('POST /api/v1/auth/register', () => {
  it('creates a new user and returns tokens', async () => {
    const response = await supertest(app.server)
      .post('/api/v1/auth/register')
      .send({ email: 'test@example.com', password: 'password123', name: 'Test User' })
      .expect(201);

    expect(response.body).toMatchObject({
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
      user: {
        email: 'test@example.com',
        name: 'Test User',
      },
    });
  });

  it('returns 409 if email already registered', async () => {
    await supertest(app.server)
      .post('/api/v1/auth/register')
      .send({ email: 'test@example.com', password: 'password123', name: 'Test User' });

    const response = await supertest(app.server)
      .post('/api/v1/auth/register')
      .send({ email: 'test@example.com', password: 'password123', name: 'Test User' })
      .expect(409);

    expect(response.body.error.code).toBe('CONFLICT');
  });

  it('returns 400 for invalid email', async () => {
    const response = await supertest(app.server)
      .post('/api/v1/auth/register')
      .send({ email: 'not-an-email', password: 'password123', name: 'Test' })
      .expect(400);

    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });
});

describe('POST /api/v1/auth/login', () => {
  it('returns tokens for valid credentials', async () => {
    await supertest(app.server)
      .post('/api/v1/auth/register')
      .send({ email: 'test@example.com', password: 'password123', name: 'Test User' });

    const response = await supertest(app.server)
      .post('/api/v1/auth/login')
      .send({ email: 'test@example.com', password: 'password123' })
      .expect(200);

    expect(response.body.accessToken).toBeDefined();
  });

  it('returns 401 for wrong password', async () => {
    await supertest(app.server)
      .post('/api/v1/auth/register')
      .send({ email: 'test@example.com', password: 'password123', name: 'Test User' });

    await supertest(app.server)
      .post('/api/v1/auth/login')
      .send({ email: 'test@example.com', password: 'wrongpassword' })
      .expect(401);
  });
});
