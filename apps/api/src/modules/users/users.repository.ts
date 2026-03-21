import { prisma } from '../../db/client.js';

export class UsersRepository {
  findById(id: string) {
    return prisma.user.findUnique({
      where: { id },
      select: { id: true, email: true, name: true, createdAt: true, updatedAt: true },
    });
  }

  findAll(page: number, limit: number) {
    const skip = (page - 1) * limit;
    return Promise.all([
      prisma.user.findMany({
        skip,
        take: limit,
        select: { id: true, email: true, name: true, createdAt: true, updatedAt: true },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.user.count(),
    ]);
  }

  update(id: string, data: { name?: string; email?: string }) {
    return prisma.user.update({
      where: { id },
      data,
      select: { id: true, email: true, name: true, createdAt: true, updatedAt: true },
    });
  }

  delete(id: string) {
    return prisma.user.delete({ where: { id } });
  }
}
