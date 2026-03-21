import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ConflictError, UnauthorizedError } from '../../shared/errors.js';

// Mock prisma
vi.mock('../../db/client.js', () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
      create: vi.fn(),
      findUniqueOrThrow: vi.fn(),
    },
    session: {
      create: vi.fn(),
      findUnique: vi.fn(),
      delete: vi.fn(),
      deleteMany: vi.fn(),
    },
  },
}));

import { prisma } from '../../db/client.js';
import { AuthService } from './auth.service.js';

const mockApp = {
  jwt: {
    sign: vi.fn().mockReturnValue('mock-access-token'),
  },
} as unknown as Parameters<typeof AuthService>[0];

describe('AuthService', () => {
  let authService: AuthService;

  beforeEach(() => {
    authService = new AuthService(mockApp);
    vi.clearAllMocks();
  });

  describe('register', () => {
    it('throws ConflictError if email already exists', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue({
        id: '1',
        email: 'test@example.com',
        name: 'Test',
        password: 'hash',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await expect(
        authService.register({ email: 'test@example.com', password: 'pass', name: 'Test' }),
      ).rejects.toThrow(ConflictError);
    });

    it('creates user and returns tokens when email is unique', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);
      vi.mocked(prisma.user.create).mockResolvedValue({
        id: 'cuid1',
        email: 'new@example.com',
        name: 'New User',
        password: 'hash',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      vi.mocked(prisma.session.create).mockResolvedValue({
        id: 'session1',
        userId: 'cuid1',
        refreshToken: 'token',
        expiresAt: new Date(),
        createdAt: new Date(),
      });
      vi.mocked(prisma.user.findUniqueOrThrow).mockResolvedValue({
        id: 'cuid1',
        email: 'new@example.com',
        name: 'New User',
        password: 'hash',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const result = await authService.register({
        email: 'new@example.com',
        password: 'password123',
        name: 'New User',
      });

      expect(result.accessToken).toBe('mock-access-token');
      expect(result.user.email).toBe('new@example.com');
    });
  });

  describe('login', () => {
    it('throws UnauthorizedError for wrong password', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue({
        id: '1',
        email: 'test@example.com',
        name: 'Test',
        password: 'different-hash',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      await expect(
        authService.login({ email: 'test@example.com', password: 'wrongpassword' }),
      ).rejects.toThrow(UnauthorizedError);
    });

    it('throws UnauthorizedError for non-existent user', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

      await expect(
        authService.login({ email: 'nobody@example.com', password: 'pass' }),
      ).rejects.toThrow(UnauthorizedError);
    });
  });
});
