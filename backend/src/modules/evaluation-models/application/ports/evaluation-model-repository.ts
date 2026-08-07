import type { EvaluationModel, EvaluationModelItem } from '../../domain/evaluation-model';

export type CreateEvaluationModelInput = {
  teacherId: string;
  name: string;
  description?: string | null;
  sortOrder?: number;
  items?: Array<{
    name: string;
    maxScore: number;
    sortOrder: number;
    isRecovery?: boolean;
    recoversItemId?: string | null;
  }>;
};

export type UpdateEvaluationModelInput = {
  name?: string;
  description?: string | null;
  isActive?: boolean;
  sortOrder?: number;
};

export type CreateEvaluationModelItemInput = {
  teacherId: string;
  evaluationModelId: string;
  name: string;
  maxScore: number;
  sortOrder?: number;
  isRecovery?: boolean;
  recoversItemId?: string | null;
};

export type UpdateEvaluationModelItemInput = {
  name?: string;
  maxScore?: number;
  sortOrder?: number;
  isRecovery?: boolean;
  recoversItemId?: string | null;
};

export type ListEvaluationModelsFilters = {
  includeInactive?: boolean;
};

export interface EvaluationModelRepository {
  create(input: CreateEvaluationModelInput): Promise<EvaluationModel>;
  findById(teacherId: string, id: string): Promise<EvaluationModel | null>;
  list(teacherId: string, filters?: ListEvaluationModelsFilters): Promise<EvaluationModel[]>;
  update(teacherId: string, id: string, input: UpdateEvaluationModelInput): Promise<EvaluationModel>;
  softDelete(teacherId: string, id: string): Promise<void>;
  countActiveCompositions(teacherId: string, evaluationModelId: string): Promise<number>;

  createItem(input: CreateEvaluationModelItemInput): Promise<EvaluationModelItem>;
  findItemById(teacherId: string, itemId: string): Promise<EvaluationModelItem | null>;
  updateItem(
    teacherId: string,
    itemId: string,
    input: UpdateEvaluationModelItemInput,
  ): Promise<EvaluationModelItem>;
  softDeleteItem(teacherId: string, itemId: string): Promise<void>;
  reorderItems(teacherId: string, evaluationModelId: string, itemIds: string[]): Promise<EvaluationModel>;
}
