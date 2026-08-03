import type { CourseDiscipline as PrismaCourseDiscipline } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { CourseDiscipline, CourseDisciplineDetail } from '../domain/course-discipline';
import type {
  CourseDisciplineRepository,
  CreateCourseDisciplineInput,
} from '../application/ports/course-discipline-repository';

function mapCourseDiscipline(row: PrismaCourseDiscipline): CourseDiscipline {
  return {
    id: row.id,
    teacherId: row.teacherId,
    courseId: row.courseId,
    disciplineId: row.disciplineId,
    createdAt: row.createdAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaCourseDisciplineRepository implements CourseDisciplineRepository {
  async findLink(
    teacherId: string,
    courseId: string,
    disciplineId: string,
  ): Promise<CourseDiscipline | null> {
    const row = await prisma.courseDiscipline.findFirst({
      where: { teacherId, courseId, disciplineId },
    });
    return row ? mapCourseDiscipline(row) : null;
  }

  async create(input: CreateCourseDisciplineInput): Promise<CourseDiscipline> {
    const row = await prisma.courseDiscipline.create({
      data: {
        teacherId: input.teacherId,
        courseId: input.courseId,
        disciplineId: input.disciplineId,
      },
    });
    return mapCourseDiscipline(row);
  }

  async reactivate(teacherId: string, id: string): Promise<CourseDiscipline> {
    await prisma.courseDiscipline.updateMany({
      where: { id, teacherId },
      data: { deletedAt: null },
    });
    const row = await prisma.courseDiscipline.findFirstOrThrow({ where: { id, teacherId } });
    return mapCourseDiscipline(row);
  }

  async softDeleteLink(teacherId: string, courseId: string, disciplineId: string): Promise<void> {
    await prisma.courseDiscipline.updateMany({
      where: { teacherId, courseId, disciplineId },
      data: { deletedAt: new Date() },
    });
  }

  async listByCourse(teacherId: string, courseId: string): Promise<CourseDisciplineDetail[]> {
    const rows = await prisma.courseDiscipline.findMany({
      where: { teacherId, courseId, deletedAt: null },
      include: {
        discipline: {
          select: { id: true, name: true, description: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    return rows.map((row) => ({
      ...mapCourseDiscipline(row),
      discipline: row.discipline,
    }));
  }
}
