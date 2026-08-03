import type { User as PrismaUser, UserRole as PrismaUserRole } from '@prisma/client';
import type { UserRole } from '../../../shared/domain/user-role';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { User } from '../domain/user';
import type { CreateUserInput, UserRepository } from '../application/ports/user-repository';

function mapUser(row: PrismaUser): User {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    passwordHash: row.passwordHash,
    role: row.role as UserRole,
    isActive: row.isActive,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaUserRepository implements UserRepository {
  async findByEmail(email: string): Promise<User | null> {
    const row = await prisma.user.findFirst({
      where: { email, deletedAt: null },
    });
    return row ? mapUser(row) : null;
  }

  async findById(id: string): Promise<User | null> {
    const row = await prisma.user.findFirst({
      where: { id, deletedAt: null },
    });
    return row ? mapUser(row) : null;
  }

  async create(input: CreateUserInput): Promise<User> {
    const row = await prisma.user.create({
      data: {
        name: input.name,
        email: input.email,
        passwordHash: input.passwordHash,
        role: (input.role ?? 'PROFESSOR') as PrismaUserRole,
      },
    });
    return mapUser(row);
  }
}
