import { createHash, randomBytes } from 'crypto';
import type { FastifyInstance } from 'fastify';
import type { RegisterBody, LoginBody } from '@webapp/shared-types';
import { prisma } from '../../db/client.js';
import { ConflictError, UnauthorizedError } from '../../shared/errors.js';

// NOTE: In production, replace with bcrypt or argon2
function hashPassword(password: string): string {
  return createHash('sha256').update(password).digest('hex');
}

export class AuthService {
  constructor(private readonly app: FastifyInstance) {}

  async register(body: RegisterBody) {
    const existing = await prisma.user.findUnique({ where: { email: body.email } });
    if (existing) {
      throw new ConflictError('Email already registered');
    }

    const user = await prisma.user.create({
      data: {
        email: body.email,
        name: body.name,
        password: hashPassword(body.password),
      },
    });

    return this.createTokens(user.id, user.email);
  }

  async login(body: LoginBody) {
    const user = await prisma.user.findUnique({ where: { email: body.email } });
    if (!user || user.password !== hashPassword(body.password)) {
      throw new UnauthorizedError('Invalid email or password');
    }

    return this.createTokens(user.id, user.email);
  }

  async refresh(refreshToken: string) {
    const session = await prisma.session.findUnique({
      where: { refreshToken },
      include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    // Rotate the refresh token
    await prisma.session.delete({ where: { id: session.id } });
    return this.createTokens(session.user.id, session.user.email);
  }

  async logout(refreshToken: string) {
    await prisma.session.deleteMany({ where: { refreshToken } });
  }

  private async createTokens(userId: string, email: string) {
    const accessToken = this.app.jwt.sign({ sub: userId, email }, { expiresIn: '15m' });

    const refreshToken = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    await prisma.session.create({
      data: { userId, refreshToken, expiresAt },
    });

    const user = await prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { id: true, email: true, name: true },
    });

    return { accessToken, refreshToken, user };
  }
}
