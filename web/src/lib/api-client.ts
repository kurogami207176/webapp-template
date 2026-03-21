const API_BASE = process.env['NEXT_PUBLIC_API_URL'] ?? 'http://localhost:8000';

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  user: { id: string; email: string; name: string };
}

export interface UserResponse {
  id: string;
  email: string;
  name: string;
  created_at: string;
  updated_at: string;
}

class ApiError extends Error {
  constructor(
    public readonly status: number,
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
    const body = await res.json() as { detail: string };
    throw new ApiError(res.status, body.detail ?? 'Request failed');
  }

  return res.json() as Promise<T>;
}

export const api = {
  auth: {
    register: (body: { email: string; password: string; name: string }) =>
      request<AuthResponse>('/api/v1/auth/register', { method: 'POST', body: JSON.stringify(body) }),

    login: (body: { email: string; password: string }) =>
      request<AuthResponse>('/api/v1/auth/login', { method: 'POST', body: JSON.stringify(body) }),
  },

  users: {
    list: (token: string, page = 1, limit = 20) =>
      request<{ data: UserResponse[]; pagination: Record<string, number> }>(
        `/api/v1/users/?page=${page}&limit=${limit}`,
        { headers: { Authorization: `Bearer ${token}` } },
      ),

    getById: (id: string, token: string) =>
      request<UserResponse>(`/api/v1/users/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      }),
  },
};
