import type {
  EvaluationModelItem as PrismaEvaluationModelItem,
  GradeComposition as PrismaGradeComposition,
  GradeCompositionActivity as PrismaGradeCompositionActivity,
  GradeCompositionGroup as PrismaGradeCompositionGroup,
} from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type {
  CompositionSyncResult,
  GradeCompositionRepository,
  UpsertGradeCompositionInput,
} from '../application/ports/grade-composition-repository';
import type {
  EligibleActivity,
  GradeComposition,
  GradeCompositionActivity,
  GradeCompositionGroup,
} from '../domain/grade-composition';

type GroupRow = PrismaGradeCompositionGroup & {
  evaluationModelItem: PrismaEvaluationModelItem;
  activities: Array<
    PrismaGradeCompositionActivity & {
      activity?: { title: string; description: string | null; maxScore: unknown };
    }
  >;
};

type CompositionRow = PrismaGradeComposition & {
  evaluationModel?: { name: string };
  groups: GroupRow[];
};

function mapActivity(
  row: PrismaGradeCompositionActivity & {
    activity?: { title: string; description: string | null; maxScore: unknown };
  },
): GradeCompositionActivity {
  return {
    id: row.id,
    teacherId: row.teacherId,
    gradeCompositionGroupId: row.gradeCompositionGroupId,
    activityId: row.activityId,
    weight: row.weight === null ? null : Number(row.weight),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    activityTitle: row.activity?.title,
    activityDescription: row.activity?.description,
    activityMaxScore:
      row.activity?.maxScore !== undefined ? Number(row.activity.maxScore) : undefined,
  };
}

function mapGroup(row: GroupRow): GradeCompositionGroup {
  return {
    id: row.id,
    teacherId: row.teacherId,
    gradeCompositionId: row.gradeCompositionId,
    evaluationModelItemId: row.evaluationModelItemId,
    calculationMethod: row.calculationMethod,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    itemName: row.evaluationModelItem.name,
    itemMaxScore: Number(row.evaluationModelItem.maxScore),
    itemSortOrder: row.evaluationModelItem.sortOrder,
    isRecovery: row.evaluationModelItem.isRecovery,
    recoversItemId: row.evaluationModelItem.recoversItemId,
    activities: row.activities.map(mapActivity),
  };
}

function mapComposition(row: CompositionRow): GradeComposition {
  const groups = [...row.groups]
    .filter((group) => group.evaluationModelItem.deletedAt === null)
    .sort((a, b) => a.evaluationModelItem.sortOrder - b.evaluationModelItem.sortOrder)
    .map(mapGroup);

  return {
    id: row.id,
    teacherId: row.teacherId,
    classId: row.classId,
    disciplineId: row.disciplineId,
    assessmentPeriodId: row.assessmentPeriodId,
    evaluationModelId: row.evaluationModelId,
    status: row.status,
    finalizedAt: row.finalizedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
    evaluationModelName: row.evaluationModel?.name,
    groups,
  };
}

const compositionInclude = {
  evaluationModel: { select: { name: true } },
  groups: {
    include: {
      evaluationModelItem: true,
      activities: {
        include: {
          activity: { select: { title: true, description: true, maxScore: true } },
        },
      },
    },
  },
} as const;

export class PrismaGradeCompositionRepository implements GradeCompositionRepository {
  async findByContext(
    teacherId: string,
    classId: string,
    disciplineId: string,
    assessmentPeriodId: string,
  ): Promise<GradeComposition | null> {
    const row = await prisma.gradeComposition.findFirst({
      where: {
        teacherId,
        classId,
        disciplineId,
        assessmentPeriodId,
        deletedAt: null,
      },
      include: compositionInclude,
    });
    return row ? mapComposition(row) : null;
  }

  async findById(teacherId: string, id: string): Promise<GradeComposition | null> {
    const row = await prisma.gradeComposition.findFirst({
      where: { id, teacherId, deletedAt: null },
      include: compositionInclude,
    });
    return row ? mapComposition(row) : null;
  }

  async findByContextIncludingDeleted(
    teacherId: string,
    classId: string,
    disciplineId: string,
    assessmentPeriodId: string,
  ): Promise<GradeComposition | null> {
    const row = await prisma.gradeComposition.findFirst({
      where: { teacherId, classId, disciplineId, assessmentPeriodId },
      include: compositionInclude,
    });
    return row ? mapComposition(row) : null;
  }

  async upsert(input: UpsertGradeCompositionInput): Promise<GradeComposition> {
    const existing = await this.findByContextIncludingDeleted(
      input.teacherId,
      input.classId,
      input.disciplineId,
      input.assessmentPeriodId,
    );

    const compositionId = await prisma.$transaction(async (tx) => {
      let id: string;

      if (existing) {
        id = existing.id;
        await tx.gradeCompositionActivity.deleteMany({
          where: {
            teacherId: input.teacherId,
            group: { gradeCompositionId: id },
          },
        });
        await tx.gradeCompositionGroup.deleteMany({
          where: { teacherId: input.teacherId, gradeCompositionId: id },
        });
        await tx.gradeComposition.update({
          where: { id },
          data: {
            evaluationModelId: input.evaluationModelId,
            deletedAt: null,
            status: 'DRAFT',
            finalizedAt: null,
          },
        });
      } else {
        const created = await tx.gradeComposition.create({
          data: {
            teacherId: input.teacherId,
            classId: input.classId,
            disciplineId: input.disciplineId,
            assessmentPeriodId: input.assessmentPeriodId,
            evaluationModelId: input.evaluationModelId,
            status: 'DRAFT',
          },
        });
        id = created.id;
      }

      for (const group of input.groups) {
        const createdGroup = await tx.gradeCompositionGroup.create({
          data: {
            teacherId: input.teacherId,
            gradeCompositionId: id,
            evaluationModelItemId: group.evaluationModelItemId,
            calculationMethod: group.calculationMethod,
          },
        });

        if (group.activities.length > 0) {
          await tx.gradeCompositionActivity.createMany({
            data: group.activities.map((activity) => ({
              teacherId: input.teacherId,
              gradeCompositionGroupId: createdGroup.id,
              activityId: activity.activityId,
              weight: activity.weight ?? null,
            })),
          });
        }
      }

      return id;
    });

    const row = await prisma.gradeComposition.findFirstOrThrow({
      where: { id: compositionId, teacherId: input.teacherId },
      include: compositionInclude,
    });
    return mapComposition(row);
  }

  async softDelete(teacherId: string, id: string): Promise<void> {
    const now = new Date();
    await prisma.gradeComposition.updateMany({
      where: { id, teacherId, deletedAt: null },
      data: { deletedAt: now },
    });
  }

  async syncGroupsWithModel(
    teacherId: string,
    compositionId: string,
  ): Promise<{ composition: GradeComposition; sync: CompositionSyncResult }> {
    const composition = await this.findById(teacherId, compositionId);
    if (!composition) {
      throw new Error('Composition not found');
    }

    if (composition.status === 'FINALIZED') {
      return { composition, sync: { groupsAdded: 0, groupsRemoved: 0 } };
    }

    const modelItems = await prisma.evaluationModelItem.findMany({
      where: {
        teacherId,
        evaluationModelId: composition.evaluationModelId,
        deletedAt: null,
      },
      orderBy: { sortOrder: 'asc' },
    });

    const activeItemIds = new Set(modelItems.map((item) => item.id));
    const existingByItem = new Map(
      composition.groups.map((group) => [group.evaluationModelItemId, group]),
    );

    let groupsAdded = 0;
    let groupsRemoved = 0;

    await prisma.$transaction(async (tx) => {
      for (const group of composition.groups) {
        if (!activeItemIds.has(group.evaluationModelItemId)) {
          await tx.gradeCompositionActivity.deleteMany({
            where: { teacherId, gradeCompositionGroupId: group.id },
          });
          await tx.gradeCompositionGroup.deleteMany({
            where: { teacherId, id: group.id },
          });
          groupsRemoved += 1;
        }
      }

      for (const item of modelItems) {
        if (!existingByItem.has(item.id)) {
          await tx.gradeCompositionGroup.create({
            data: {
              teacherId,
              gradeCompositionId: compositionId,
              evaluationModelItemId: item.id,
              calculationMethod: 'SIMPLE_AVERAGE',
            },
          });
          groupsAdded += 1;
        }
      }
    });

    const refreshed = await this.findById(teacherId, compositionId);
    return {
      composition: refreshed!,
      sync: { groupsAdded, groupsRemoved },
    };
  }

  async listEligibleActivities(
    teacherId: string,
    classId: string,
    disciplineId: string,
    assessmentPeriodId: string,
  ): Promise<EligibleActivity[]> {
    const rows = await prisma.activity.findMany({
      where: {
        teacherId,
        classId,
        assessmentPeriodId,
        deletedAt: null,
        activityDisciplines: {
          some: { disciplineId, deletedAt: null },
        },
      },
      orderBy: [{ dueDate: 'asc' }, { title: 'asc' }],
      select: {
        id: true,
        title: true,
        maxScore: true,
        tag: true,
        dueDate: true,
      },
    });

    return rows.map((row) => ({
      id: row.id,
      title: row.title,
      maxScore: Number(row.maxScore),
      tag: row.tag,
      dueDate: row.dueDate,
    }));
  }

  async loadCalculationData(teacherId: string, compositionId: string) {
    const composition = await this.findById(teacherId, compositionId);
    if (!composition) {
      throw new Error('Composition not found');
    }

    const students = await prisma.enrollment.findMany({
      where: {
        teacherId,
        classId: composition.classId,
        status: 'ACTIVE',
        deletedAt: null,
        student: { deletedAt: null },
      },
      include: { student: { select: { id: true, name: true } } },
      orderBy: { student: { name: 'asc' } },
    });

    const activityIds = composition.groups.flatMap((group) =>
      group.activities.map((activity) => activity.activityId),
    );

    const activities = activityIds.length
      ? await prisma.activity.findMany({
          where: { teacherId, id: { in: activityIds }, deletedAt: null },
          select: { id: true, maxScore: true },
        })
      : [];

    const activityMaxScores = new Map(
      activities.map((activity) => [activity.id, Number(activity.maxScore)]),
    );

    const submissions = activityIds.length
      ? await prisma.submission.findMany({
          where: {
            teacherId,
            activityId: { in: activityIds },
            deletedAt: null,
          },
          select: {
            studentId: true,
            activityId: true,
            score: true,
            status: true,
          },
        })
      : [];

    const scoresByStudentActivity = new Map<string, Map<string, number | null>>();
    for (const student of students) {
      scoresByStudentActivity.set(student.studentId, new Map());
    }
    for (const submission of submissions) {
      let studentMap = scoresByStudentActivity.get(submission.studentId);
      if (!studentMap) {
        studentMap = new Map();
        scoresByStudentActivity.set(submission.studentId, studentMap);
      }
      const score =
        submission.status === 'GRADED' && submission.score !== null
          ? Number(submission.score)
          : null;
      studentMap.set(submission.activityId, score);
    }

    const eligible = await this.listEligibleActivities(
      teacherId,
      composition.classId,
      composition.disciplineId,
      composition.assessmentPeriodId,
    );

    return {
      composition,
      students: students.map((row) => ({
        id: row.student.id,
        name: row.student.name,
      })),
      scoresByStudentActivity,
      activityMaxScores,
      eligibleActivityIds: eligible.map((activity) => activity.id),
    };
  }
}
