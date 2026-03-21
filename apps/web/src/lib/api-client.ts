import type { AuthResponse, LoginBody, RegisterBody, User } from '@webapp/shared-types';

const API_BASE = process.env['NEXT_PUBLIC_API_URL'] ?? 'http://localhost:3000';

class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  if (!res.ok) {
    const body = (await res.json()) as { error: { code: string; message: string } };
    throw new ApiError(res.status, body.error.code, body.error.message);
  }

  return res.json() as Promise<T>;
}

export const api = {
  auth: {
    register: (body: RegisterBody) =>
      request<AuthResponse>('/api/v1/auth/register', {
        method: 'POST',
        body: JSON.stringify(body),
      }),

    login: (body: LoginBody) =>
      request<AuthResponse>('/api/v1/auth/login', {
        method: 'POST',
        body: JSON.stringify(body),
      }),
  },

  users: {
    me: (token: string) =>
      request<User>('/api/v1/users/me', {
        headers: { Authorization: `Bearer ${token}` },
      }),
  },
};
