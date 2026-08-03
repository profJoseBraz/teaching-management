import type { Class as PrismaClass } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { Class, ClassShift, ClassStatus } from '../domain/class';
import type {
  ClassRepository,
  CreateClassInput,
  ListClassesFilters,
  UpdateClassInput,
} from '../application/ports/class-repository';

function mapClass(row: PrismaClass): Class {
  return {
    id: row.id,
    teacherId: row.teacherId,
    academicYearId: row.academicYearId,
    courseId: row.courseId,
    name: row.name,
    shift: row.shift as ClassShift | null,
    status: row.status as ClassStatus,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaClassRepository implements ClassRepository {
  async create(input: CreateClassInput): Promise<Class> {
    const row = await prisma.class.create({
      data: {
        teacherId: input.teacherId,
        academicYearId: input.academicYearId,
        courseId: input.courseId,
        name: input.name,
        shift: input.shift ?? null,
      },
    });
    return mapClass(row);
  }

  async findById(teacherId: string, id: string): Promise<Class | null> {
    const row = await prisma.class.findFirst({ where: { id, teacherId } });
    return row ? mapClass(row) : null;
  }

  async findByComposition(
    teacherId: string,
    academicYearId: string,
    courseId: string,
    name: string,
  ): Promise<Class | null> {
    const row = await prisma.class.findFirst({
      where: { teacherId, academicYearId, courseId, name },
    });
    return row ? mapClass(row) : null;
  }

  async list(teacherId: string, filters?: ListClassesFilters): Promise<Class[]> {
    const rows = await prisma.class.findMany({
      where: {
        teacherId,
        deletedAt: null,
        ...(filters?.academicYearId ? { academicYearId: filters.academicYearId } : {}),
        ...(filters?.courseId ? { courseId: filters.courseId } : {}),
        ...(filters?.disciplineId
          ? { classDisciplines: { some: { disciplineId: filters.disciplineId, deletedAt: null } } }
          : {}),
        ...(filters?.status ? { status: filters.status } : {}),
      },
      orderBy: { name: 'asc' },
    });
    return rows.map(mapClass);
  }

  async update(teacherId: string, id: string, input: UpdateClassInput): Promise<Class> {
    await prisma.class.updateMany({
      where: { id, teacherId },
      data: {
        ...(input.name !== undefined ? { name: input.name } : {}),
        ...(input.shift !== undefined ? { shift: input.shift } : {}),
      },
    });
    const row = await prisma.class.findFirstOrThrow({ where: { id, teacherId } });
    return mapClass(row);
  }

  async archive(teacherId: string, id: string): Promise<Class> {
    await prisma.class.updateMany({
      where: { id, teacherId },
      data: { status: 'ARCHIVED' },
    });
    const row = await prisma.class.findFirstOrThrow({ where: { id, teacherId } });
    return mapClass(row);
  }
}
