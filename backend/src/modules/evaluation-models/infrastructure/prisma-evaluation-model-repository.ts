import type {
  EvaluationModel as PrismaEvaluationModel,
  EvaluationModelItem as PrismaEvaluationModelItem,
} from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type {
  CreateEvaluationModelInput,
  CreateEvaluationModelItemInput,
  EvaluationModelRepository,
  ListEvaluationModelsFilters,
  UpdateEvaluationModelInput,
  UpdateEvaluationModelItemInput,
} from '../application/ports/evaluation-model-repository';
import type { EvaluationModel, EvaluationModelItem } from '../domain/evaluation-model';

type ModelRow = PrismaEvaluationModel & { items: PrismaEvaluationModelItem[] };

function mapItem(row: PrismaEvaluationModelItem): EvaluationModelItem {
  return {
    id: row.id,
    teacherId: row.teacherId,
    evaluationModelId: row.evaluationModelId,
    name: row.name,
    maxScore: Number(row.maxScore),
    sortOrder: row.sortOrder,
    isRecovery: row.isRecovery,
    recoversItemId: row.recoversItemId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

function mapModel(row: ModelRow): EvaluationModel {
  const items = row.items
    .filter((item) => item.deletedAt === null)
    .sort((a, b) => a.sortOrder - b.sortOrder)
    .map(mapItem);

  return {
    id: row.id,
    teacherId: row.teacherId,
    name: row.name,
    description: row.description,
    isActive: row.isActive,
    sortOrder: row.sortOrder,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
    items,
  };
}

const itemsInclude = {
  items: {
    where: { deletedAt: null },
    orderBy: { sortOrder: 'asc' as const },
  },
};

export class PrismaEvaluationModelRepository implements EvaluationModelRepository {
  async create(input: CreateEvaluationModelInput): Promise<EvaluationModel> {
    const row = await prisma.evaluationModel.create({
      data: {
        teacherId: input.teacherId,
        name: input.name,
        description: input.description ?? null,
        sortOrder: input.sortOrder ?? 0,
        items: input.items?.length
          ? {
              create: input.items.map((item) => ({
                teacherId: input.teacherId,
                name: item.name,
                maxScore: item.maxScore,
                sortOrder: item.sortOrder,
              })),
            }
          : undefined,
      },
      include: itemsInclude,
    });
    return mapModel(row);
  }

  async findById(teacherId: string, id: string): Promise<EvaluationModel | null> {
    const row = await prisma.evaluationModel.findFirst({
      where: { id, teacherId, deletedAt: null },
      include: itemsInclude,
    });
    return row ? mapModel(row) : null;
  }

  async list(teacherId: string, filters?: ListEvaluationModelsFilters): Promise<EvaluationModel[]> {
    const rows = await prisma.evaluationModel.findMany({
      where: {
        teacherId,
        deletedAt: null,
        ...(filters?.includeInactive ? {} : { isActive: true }),
      },
      include: itemsInclude,
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
    return rows.map(mapModel);
  }

  async update(
    teacherId: string,
    id: string,
    input: UpdateEvaluationModelInput,
  ): Promise<EvaluationModel> {
    await prisma.evaluationModel.updateMany({
      where: { id, teacherId, deletedAt: null },
      data: {
        ...(input.name !== undefined ? { name: input.name } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.isActive !== undefined ? { isActive: input.isActive } : {}),
        ...(input.sortOrder !== undefined ? { sortOrder: input.sortOrder } : {}),
      },
    });
    const row = await prisma.evaluationModel.findFirstOrThrow({
      where: { id, teacherId, deletedAt: null },
      include: itemsInclude,
    });
    return mapModel(row);
  }

  async softDelete(teacherId: string, id: string): Promise<void> {
    const now = new Date();
    await prisma.$transaction([
      prisma.evaluationModelItem.updateMany({
        where: { evaluationModelId: id, teacherId, deletedAt: null },
        data: { deletedAt: now },
      }),
      prisma.evaluationModel.updateMany({
        where: { id, teacherId, deletedAt: null },
        data: { deletedAt: now, isActive: false },
      }),
    ]);
  }

  async countActiveCompositions(teacherId: string, evaluationModelId: string): Promise<number> {
    return prisma.gradeComposition.count({
      where: { teacherId, evaluationModelId, deletedAt: null },
    });
  }

  async createItem(input: CreateEvaluationModelItemInput): Promise<EvaluationModelItem> {
    let sortOrder = input.sortOrder;
    if (sortOrder === undefined) {
      const max = await prisma.evaluationModelItem.aggregate({
        where: {
          evaluationModelId: input.evaluationModelId,
          teacherId: input.teacherId,
          deletedAt: null,
        },
        _max: { sortOrder: true },
      });
      sortOrder = (max._max.sortOrder ?? -1) + 1;
    }

    const row = await prisma.evaluationModelItem.create({
      data: {
        teacherId: input.teacherId,
        evaluationModelId: input.evaluationModelId,
        name: input.name,
        maxScore: input.maxScore,
        sortOrder,
        isRecovery: input.isRecovery ?? false,
        recoversItemId: input.isRecovery ? (input.recoversItemId ?? null) : null,
      },
    });
    return mapItem(row);
  }

  async findItemById(teacherId: string, itemId: string): Promise<EvaluationModelItem | null> {
    const row = await prisma.evaluationModelItem.findFirst({
      where: { id: itemId, teacherId, deletedAt: null },
    });
    return row ? mapItem(row) : null;
  }

  async updateItem(
    teacherId: string,
    itemId: string,
    input: UpdateEvaluationModelItemInput,
  ): Promise<EvaluationModelItem> {
    const isRecovery = input.isRecovery;
    await prisma.evaluationModelItem.updateMany({
      where: { id: itemId, teacherId, deletedAt: null },
      data: {
        ...(input.name !== undefined ? { name: input.name } : {}),
        ...(input.maxScore !== undefined ? { maxScore: input.maxScore } : {}),
        ...(input.sortOrder !== undefined ? { sortOrder: input.sortOrder } : {}),
        ...(isRecovery !== undefined ? { isRecovery } : {}),
        ...(isRecovery === false
          ? { recoversItemId: null }
          : input.recoversItemId !== undefined
            ? { recoversItemId: input.recoversItemId }
            : {}),
      },
    });
    const row = await prisma.evaluationModelItem.findFirstOrThrow({
      where: { id: itemId, teacherId, deletedAt: null },
    });
    return mapItem(row);
  }

  async softDeleteItem(teacherId: string, itemId: string): Promise<void> {
    const now = new Date();
    await prisma.$transaction(async (tx) => {
      // Soft-delete também recuperações que apontam para este item.
      const related = await tx.evaluationModelItem.findMany({
        where: {
          teacherId,
          deletedAt: null,
          OR: [{ id: itemId }, { recoversItemId: itemId }],
        },
        select: { id: true },
      });
      const itemIds = related.map((row) => row.id);

      await tx.evaluationModelItem.updateMany({
        where: { id: { in: itemIds }, teacherId, deletedAt: null },
        data: { deletedAt: now },
      });

      const groups = await tx.gradeCompositionGroup.findMany({
        where: { teacherId, evaluationModelItemId: { in: itemIds } },
        select: { id: true },
      });
      const groupIds = groups.map((g) => g.id);
      if (groupIds.length > 0) {
        await tx.gradeCompositionActivity.deleteMany({
          where: { teacherId, gradeCompositionGroupId: { in: groupIds } },
        });
        await tx.gradeCompositionGroup.deleteMany({
          where: { teacherId, id: { in: groupIds } },
        });
      }
    });
  }

  async reorderItems(
    teacherId: string,
    evaluationModelId: string,
    itemIds: string[],
  ): Promise<EvaluationModel> {
    await prisma.$transaction(
      itemIds.map((id, index) =>
        prisma.evaluationModelItem.updateMany({
          where: { id, teacherId, evaluationModelId, deletedAt: null },
          data: { sortOrder: index },
        }),
      ),
    );
    const row = await prisma.evaluationModel.findFirstOrThrow({
      where: { id: evaluationModelId, teacherId, deletedAt: null },
      include: itemsInclude,
    });
    return mapModel(row);
  }
}
