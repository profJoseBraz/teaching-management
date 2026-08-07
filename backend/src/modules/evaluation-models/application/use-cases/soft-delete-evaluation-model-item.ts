import { NotFoundError } from '../../../../shared/domain/errors';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export class SoftDeleteEvaluationModelItemUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(teacherId: string, evaluationModelId: string, itemId: string): Promise<void> {
    const model = await this.models.findById(teacherId, evaluationModelId);
    if (!model) {
      throw new NotFoundError('Evaluation model not found');
    }

    const item = await this.models.findItemById(teacherId, itemId);
    if (!item || item.evaluationModelId !== evaluationModelId) {
      throw new NotFoundError('Evaluation model item not found');
    }

    await this.models.softDeleteItem(teacherId, itemId);
  }
}
