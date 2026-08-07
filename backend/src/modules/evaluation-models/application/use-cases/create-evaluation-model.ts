import { ValidationError } from '../../../../shared/domain/errors';
import type { EvaluationModel } from '../../domain/evaluation-model';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export type CreateEvaluationModelRequest = {
  teacherId: string;
  name: string;
  description?: string | null;
  sortOrder?: number;
  items?: Array<{ name: string; maxScore: number; sortOrder?: number }>;
};

export class CreateEvaluationModelUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(input: CreateEvaluationModelRequest): Promise<EvaluationModel> {
    const name = input.name.trim();
    if (!name) {
      throw new ValidationError('Evaluation model name is required');
    }

    const items = (input.items ?? []).map((item, index) => {
      const itemName = item.name.trim();
      if (!itemName) {
        throw new ValidationError('Evaluation model item name is required');
      }
      if (item.maxScore <= 0) {
        throw new ValidationError('Item maxScore must be greater than zero');
      }
      return {
        name: itemName,
        maxScore: item.maxScore,
        sortOrder: item.sortOrder ?? index,
      };
    });

    return this.models.create({
      teacherId: input.teacherId,
      name,
      description: input.description?.trim() || null,
      sortOrder: input.sortOrder,
      items,
    });
  }
}
