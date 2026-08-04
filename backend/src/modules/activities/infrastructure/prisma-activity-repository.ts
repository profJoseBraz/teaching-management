import type {
  Activity as PrismaActivity,
  ActivityCategory as PrismaActivityCategory,
  ActivityGradeMode as PrismaActivityGradeMode,
  ActivityMode as PrismaActivityMode,
} from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type {
  Activity,
  ActivityCategory,
  ActivityGradeMode,
  ActivityMode,
} from '../domain/activity';
import type {
  ActivityRepository,
  CreateActivityInput,
  ListActivitiesFilters,
  UpdateActivityInput,
} from '../application/ports/activity-repository';

function mapActivity(row: PrismaActivity): Activity {
  return {
    id: row.id,
    teacherId: row.teacherId,
    classId: row.classId,
    disciplineId: row.disciplineId,
    originLessonId: row.originLessonId,
    assessmentPeriodId: row.assessmentPeriodId,
    title: row.title,
    description: row.description,
    tag: row.tag,
    category: row.category as ActivityCategory,
    mode: row.mode as ActivityMode,
    gradeMode: row.gradeMode as ActivityGradeMode,
    maxScore: Number(row.maxScore),
    createdOn: row.createdOn,
    dueDate: row.dueDate,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaActivityRepository implements ActivityRepository {
  async create(input: CreateActivityInput): Promise<Activity> {
    const row = await prisma.activity.create({
      data: {
        teacherId: input.teacherId,
        classId: input.classId,
        disciplineId: input.disciplineId,
        originLessonId: input.originLessonId ?? null,
        assessmentPeriodId: input.assessmentPeriodId ?? null,
        title: input.title,
        description: input.description ?? null,
        tag: input.tag ?? null,
        category: input.category as PrismaActivityCategory,
        mode: input.mode as PrismaActivityMode,
        gradeMode: input.gradeMode as PrismaActivityGradeMode,
        maxScore: input.maxScore,
        dueDate: input.dueDate,
      },
    });
    return mapActivity(row);
  }

  async update(id: string, teacherId: string, input: UpdateActivityInput): Promise<Activity> {
    const row = await prisma.activity.update({
      where: { id, teacherId, deletedAt: null },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.tag !== undefined ? { tag: input.tag } : {}),
        ...(input.category !== undefined ? { category: input.category as PrismaActivityCategory } : {}),
        ...(input.mode !== undefined ? { mode: input.mode as PrismaActivityMode } : {}),
        ...(input.gradeMode !== undefined
          ? { gradeMode: input.gradeMode as PrismaActivityGradeMode }
          : {}),
        ...(input.maxScore !== undefined ? { maxScore: input.maxScore } : {}),
        ...(input.dueDate !== undefined ? { dueDate: input.dueDate } : {}),
        ...(input.assessmentPeriodId !== undefined
          ? { assessmentPeriodId: input.assessmentPeriodId }
          : {}),
      },
    });
    return mapActivity(row);
  }

  async findById(id: string, teacherId: string): Promise<Activity | null> {
    const row = await prisma.activity.findFirst({
      where: { id, teacherId, deletedAt: null },
    });
    return row ? mapActivity(row) : null;
  }

  async listByClass(
    classId: string,
    teacherId: string,
    filters: ListActivitiesFilters = {},
  ): Promise<Activity[]> {
    const rows = await prisma.activity.findMany({
      where: {
        classId,
        teacherId,
        deletedAt: null,
        ...(filters.disciplineId ? { disciplineId: filters.disciplineId } : {}),
        ...(filters.tag
          ? { tag: { equals: filters.tag, mode: 'insensitive' as const } }
          : {}),
      },
      orderBy: { dueDate: 'asc' },
    });
    return rows.map(mapActivity);
  }

  async softDelete(id: string, teacherId: string): Promise<void> {
    const now = new Date();
    await prisma.$transaction([
      prisma.activity.updateMany({
        where: { id, teacherId, deletedAt: null },
        data: { deletedAt: now },
      }),
      prisma.submission.updateMany({
        where: { activityId: id, teacherId, deletedAt: null },
        data: { deletedAt: now },
      }),
      prisma.activityGroup.updateMany({
        where: { activityId: id, teacherId, deletedAt: null },
        data: { deletedAt: now },
      }),
    ]);
  }
}
