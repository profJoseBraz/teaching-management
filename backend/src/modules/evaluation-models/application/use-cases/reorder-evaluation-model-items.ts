import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { EvaluationModel } from '../../domain/evaluation-model';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export class ReorderEvaluationModelItemsUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(
    teacherId: string,
    evaluationModelId: string,
    itemIds: string[],
  ): Promise<EvaluationModel> {
    const model = await this.models.findById(teacherId, evaluationModelId);
    if (!model) {
      throw new NotFoundError('Evaluation model not found');
    }

    const currentIds = model.items.map((item) => item.id).sort();
    const incoming = [...itemIds].sort();
    if (
      currentIds.length !== incoming.length ||
      currentIds.some((id, index) => id !== incoming[index])
    ) {
      throw new ValidationError('itemIds must contain exactly the active items of the model');
    }

    return this.models.reorderItems(teacherId, evaluationModelId, itemIds);
  }
}
