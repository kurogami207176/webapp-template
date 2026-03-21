import type { UpdateUserBody } from '@webapp/shared-types';
import { NotFoundError } from '../../shared/errors.js';
import { UsersRepository } from './users.repository.js';

export class UsersService {
  constructor(private readonly repo: UsersRepository) {}

  async getById(id: string) {
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundError('User', id);
    return user;
  }

  async list(page: number, limit: number) {
    const [users, total] = await this.repo.findAll(page, limit);
    return {
      data: users,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    };
  }

  async update(id: string, body: UpdateUserBody) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('User', id);
    return this.repo.update(id, body);
  }

  async delete(id: string) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundError('User', id);
    await this.repo.delete(id);
  }
}
