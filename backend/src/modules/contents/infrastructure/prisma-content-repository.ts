import type { Content as PrismaContent, ContentStatus as PrismaContentStatus } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { Content, ContentStatus } from '../domain/content';
import type {
  ContentRepository,
  CreateContentInput,
  ListContentsFilters,
  UpdateContentInput,
} from '../application/ports/content-repository';

function mapContent(row: PrismaContent): Content {
  return {
    id: row.id,
    teacherId: row.teacherId,
    classId: row.classId,
    disciplineId: row.disciplineId,
    assessmentPeriodId: row.assessmentPeriodId,
    title: row.title,
    description: row.description,
    status: row.status as ContentStatus,
    startedAt: row.startedAt,
    completedAt: row.completedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaContentRepository implements ContentRepository {
  async create(input: CreateContentInput): Promise<Content> {
    const row = await prisma.content.create({
      data: {
        teacherId: input.teacherId,
        classId: input.classId,
        disciplineId: input.disciplineId,
        assessmentPeriodId: input.assessmentPeriodId,
        title: input.title,
        description: input.description ?? null,
      },
    });
    return mapContent(row);
  }

  async update(id: string, teacherId: string, input: UpdateContentInput): Promise<Content> {
    const row = await prisma.content.update({
      where: { id, teacherId, deletedAt: null },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.assessmentPeriodId !== undefined
          ? { assessmentPeriodId: input.assessmentPeriodId }
          : {}),
      },
    });
    return mapContent(row);
  }

  async findById(id: string, teacherId: string): Promise<Content | null> {
    const row = await prisma.content.findFirst({
      where: { id, teacherId, deletedAt: null },
    });
    return row ? mapContent(row) : null;
  }

  async listByClass(
    classId: string,
    teacherId: string,
    filters: ListContentsFilters = {},
  ): Promise<Content[]> {
    const rows = await prisma.content.findMany({
      where: {
        classId,
        teacherId,
        deletedAt: null,
        ...(filters.status ? { status: filters.status as PrismaContentStatus } : {}),
        ...(filters.disciplineId ? { disciplineId: filters.disciplineId } : {}),
        ...(filters.assessmentPeriodId
          ? { assessmentPeriodId: filters.assessmentPeriodId }
          : {}),
      },
      orderBy: { startedAt: 'desc' },
    });
    return rows.map(mapContent);
  }

  async setStatus(
    id: string,
    teacherId: string,
    status: ContentStatus,
    completedAt: Date | null,
  ): Promise<Content> {
    const row = await prisma.content.update({
      where: { id, teacherId, deletedAt: null },
      data: { status: status as PrismaContentStatus, completedAt },
    });
    return mapContent(row);
  }
}
