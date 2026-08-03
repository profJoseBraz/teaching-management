import type { Lesson as PrismaLesson } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { Lesson } from '../domain/lesson';
import type {
  CreateLessonInput,
  LessonRepository,
  UpdateLessonInput,
} from '../application/ports/lesson-repository';

function mapLesson(row: PrismaLesson): Lesson {
  return {
    id: row.id,
    teacherId: row.teacherId,
    classId: row.classId,
    disciplineId: row.disciplineId,
    date: row.date,
    startTime: row.startTime,
    endTime: row.endTime,
    observations: row.observations,
    attendanceCompleted: row.attendanceCompleted,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaLessonRepository implements LessonRepository {
  async create(input: CreateLessonInput): Promise<Lesson> {
    const row = await prisma.lesson.create({
      data: {
        teacherId: input.teacherId,
        classId: input.classId,
        disciplineId: input.disciplineId,
        date: input.date,
        startTime: input.startTime,
        endTime: input.endTime,
        observations: input.observations ?? null,
      },
    });
    return mapLesson(row);
  }

  async update(id: string, teacherId: string, input: UpdateLessonInput): Promise<Lesson> {
    const row = await prisma.lesson.update({
      where: { id, teacherId, deletedAt: null },
      data: {
        ...(input.date !== undefined ? { date: input.date } : {}),
        ...(input.startTime !== undefined ? { startTime: input.startTime } : {}),
        ...(input.endTime !== undefined ? { endTime: input.endTime } : {}),
        ...(input.observations !== undefined ? { observations: input.observations } : {}),
      },
    });
    return mapLesson(row);
  }

  async findById(id: string, teacherId: string): Promise<Lesson | null> {
    const row = await prisma.lesson.findFirst({
      where: { id, teacherId, deletedAt: null },
    });
    return row ? mapLesson(row) : null;
  }

  async listByClass(classId: string, teacherId: string, disciplineId?: string): Promise<Lesson[]> {
    const rows = await prisma.lesson.findMany({
      where: {
        classId,
        teacherId,
        deletedAt: null,
        ...(disciplineId ? { disciplineId } : {}),
      },
      orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
    });
    return rows.map(mapLesson);
  }

  async softDelete(id: string, teacherId: string): Promise<void> {
    await prisma.lesson.update({
      where: { id, teacherId, deletedAt: null },
      data: { deletedAt: new Date() },
    });
  }
}
