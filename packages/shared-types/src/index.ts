import { z } from 'zod';

// ============================================================
// Common schemas
// ============================================================

export const PaginationSchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const IdParamSchema = z.object({
  id: z.string().cuid(),
});

export const ApiErrorSchema = z.object({
  error: z.object({
    code: z.string(),
    message: z.string(),
    details: z.unknown().optional(),
  }),
});

// ============================================================
// Auth schemas
// ============================================================

export const RegisterBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
  name: z.string().min(1).max(100),
});

export const LoginBodySchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

export const AuthResponseSchema = z.object({
  accessToken: z.string(),
  refreshToken: z.string(),
  user: z.object({
    id: z.string(),
    email: z.string(),
    name: z.string(),
  }),
});

export const RefreshBodySchema = z.object({
  refreshToken: z.string(),
});

// ============================================================
// User schemas
// ============================================================

export const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  name: z.string(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

export const UpdateUserBodySchema = z.object({
  name: z.string().min(1).max(100).optional(),
  email: z.string().email().optional(),
});

// ============================================================
// Inferred TypeScript types
// ============================================================

export type Pagination = z.infer<typeof PaginationSchema>;
export type IdParam = z.infer<typeof IdParamSchema>;
export type ApiError = z.infer<typeof ApiErrorSchema>;

export type RegisterBody = z.infer<typeof RegisterBodySchema>;
export type LoginBody = z.infer<typeof LoginBodySchema>;
export type AuthResponse = z.infer<typeof AuthResponseSchema>;
export type RefreshBody = z.infer<typeof RefreshBodySchema>;

export type User = z.infer<typeof UserSchema>;
export type UpdateUserBody = z.infer<typeof UpdateUserBodySchema>;
