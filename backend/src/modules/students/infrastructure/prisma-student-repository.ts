import type { Student as PrismaStudent } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { Student } from '../domain/student';
import type {
  CreateStudentInput,
  ListStudentsFilters,
  StudentRepository,
  UpdateStudentInput,
} from '../application/ports/student-repository';

function mapStudent(row: PrismaStudent): Student {
  return {
    id: row.id,
    teacherId: row.teacherId,
    name: row.name,
    registryCode: row.registryCode,
    email: row.email,
    phone: row.phone,
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaStudentRepository implements StudentRepository {
  async create(input: CreateStudentInput): Promise<Student> {
    const row = await prisma.student.create({
      data: {
        teacherId: input.teacherId,
        name: input.name,
        registryCode: input.registryCode ?? null,
        email: input.email ?? null,
        phone: input.phone ?? null,
        notes: input.notes ?? null,
      },
    });
    return mapStudent(row);
  }

  async findById(teacherId: string, id: string): Promise<Student | null> {
    const row = await prisma.student.findFirst({ where: { id, teacherId } });
    return row ? mapStudent(row) : null;
  }

  async list(teacherId: string, filters?: ListStudentsFilters): Promise<Student[]> {
    const rows = await prisma.student.findMany({
      where: {
        teacherId,
        deletedAt: null,
        ...(filters?.search
          ? { name: { contains: filters.search, mode: 'insensitive' } }
          : {}),
      },
      orderBy: { name: 'asc' },
    });
    return rows.map(mapStudent);
  }

  async update(teacherId: string, id: string, input: UpdateStudentInput): Promise<Student> {
    await prisma.student.updateMany({
      where: { id, teacherId },
      data: {
        ...(input.name !== undefined ? { name: input.name } : {}),
        ...(input.registryCode !== undefined ? { registryCode: input.registryCode } : {}),
        ...(input.email !== undefined ? { email: input.email } : {}),
        ...(input.phone !== undefined ? { phone: input.phone } : {}),
        ...(input.notes !== undefined ? { notes: input.notes } : {}),
      },
    });
    const row = await prisma.student.findFirstOrThrow({ where: { id, teacherId } });
    return mapStudent(row);
  }

  async softDelete(teacherId: string, id: string): Promise<void> {
    await prisma.student.updateMany({
      where: { id, teacherId },
      data: { deletedAt: new Date() },
    });
  }
}
