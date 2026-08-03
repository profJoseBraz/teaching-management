import type { AssessmentPeriod as PrismaAssessmentPeriod } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { AssessmentPeriod } from '../domain/assessment-period';
import type {
  AssessmentPeriodRepository,
  CreateAssessmentPeriodInput,
  UpdateAssessmentPeriodInput,
} from '../application/ports/assessment-period-repository';

function mapAssessmentPeriod(row: PrismaAssessmentPeriod): AssessmentPeriod {
  return {
    id: row.id,
    teacherId: row.teacherId,
    academicYearId: row.academicYearId,
    classId: row.classId,
    name: row.name,
    sortOrder: row.sortOrder,
    startsOn: row.startsOn,
    endsOn: row.endsOn,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaAssessmentPeriodRepository implements AssessmentPeriodRepository {
  async create(input: CreateAssessmentPeriodInput): Promise<AssessmentPeriod> {
    const nextSortOrder = await this.countByAcademicYear(input.teacherId, input.academicYearId);

    const row = await prisma.assessmentPeriod.create({
      data: {
        teacherId: input.teacherId,
        academicYearId: input.academicYearId,
        classId: input.classId ?? null,
        name: input.name,
        sortOrder: nextSortOrder,
        startsOn: input.startsOn ?? null,
        endsOn: input.endsOn ?? null,
      },
    });
    return mapAssessmentPeriod(row);
  }

  async findById(teacherId: string, id: string): Promise<AssessmentPeriod | null> {
    const row = await prisma.assessmentPeriod.findFirst({ where: { id, teacherId } });
    return row ? mapAssessmentPeriod(row) : null;
  }

  async listByAcademicYear(teacherId: string, academicYearId: string): Promise<AssessmentPeriod[]> {
    const rows = await prisma.assessmentPeriod.findMany({
      where: { teacherId, academicYearId, deletedAt: null },
      orderBy: { sortOrder: 'asc' },
    });
    return rows.map(mapAssessmentPeriod);
  }

  async countByAcademicYear(teacherId: string, academicYearId: string): Promise<number> {
    return prisma.assessmentPeriod.count({
      where: { teacherId, academicYearId, deletedAt: null },
    });
  }

  async update(
    teacherId: string,
    id: string,
    input: UpdateAssessmentPeriodInput,
  ): Promise<AssessmentPeriod> {
    await prisma.assessmentPeriod.updateMany({
      where: { id, teacherId },
      data: {
        ...(input.name !== undefined ? { name: input.name } : {}),
        ...(input.classId !== undefined ? { classId: input.classId } : {}),
        ...(input.startsOn !== undefined ? { startsOn: input.startsOn } : {}),
        ...(input.endsOn !== undefined ? { endsOn: input.endsOn } : {}),
      },
    });
    const row = await prisma.assessmentPeriod.findFirstOrThrow({ where: { id, teacherId } });
    return mapAssessmentPeriod(row);
  }

  async reorder(
    teacherId: string,
    academicYearId: string,
    orderedIds: string[],
  ): Promise<AssessmentPeriod[]> {
    await prisma.$transaction(
      orderedIds.map((id, index) =>
        prisma.assessmentPeriod.updateMany({
          where: { id, teacherId, academicYearId },
          data: { sortOrder: index },
        }),
      ),
    );
    return this.listByAcademicYear(teacherId, academicYearId);
  }
}
