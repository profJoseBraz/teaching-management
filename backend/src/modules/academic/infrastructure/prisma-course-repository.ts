import type { Course as PrismaCourse } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { Course } from '../domain/course';
import type {
  CourseRepository,
  CreateCourseInput,
  UpdateCourseInput,
} from '../application/ports/course-repository';

function mapCourse(row: PrismaCourse): Course {
  return {
    id: row.id,
    teacherId: row.teacherId,
    name: row.name,
    description: row.description,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaCourseRepository implements CourseRepository {
  async create(input: CreateCourseInput): Promise<Course> {
    const row = await prisma.course.create({
      data: {
        teacherId: input.teacherId,
        name: input.name,
        description: input.description ?? null,
      },
    });
    return mapCourse(row);
  }

  async findById(teacherId: string, id: string): Promise<Course | null> {
    const row = await prisma.course.findFirst({ where: { id, teacherId } });
    return row ? mapCourse(row) : null;
  }

  async findByName(teacherId: string, name: string): Promise<Course | null> {
    const row = await prisma.course.findFirst({ where: { teacherId, name } });
    return row ? mapCourse(row) : null;
  }

  async list(teacherId: string): Promise<Course[]> {
    const rows = await prisma.course.findMany({
      where: { teacherId, deletedAt: null },
      orderBy: { name: 'asc' },
    });
    return rows.map(mapCourse);
  }

  async update(teacherId: string, id: string, input: UpdateCourseInput): Promise<Course> {
    await prisma.course.updateMany({
      where: { id, teacherId },
      data: {
        ...(input.name !== undefined ? { name: input.name } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
      },
    });
    const row = await prisma.course.findFirstOrThrow({ where: { id, teacherId } });
    return mapCourse(row);
  }

  async softDelete(teacherId: string, id: string): Promise<void> {
    await prisma.course.updateMany({
      where: { id, teacherId },
      data: { deletedAt: new Date() },
    });
  }
}
