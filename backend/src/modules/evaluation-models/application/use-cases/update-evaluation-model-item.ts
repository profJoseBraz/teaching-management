import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { EvaluationModelItem } from '../../domain/evaluation-model';
import { assertRecoveryLink } from '../assert-recovery-link';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export class UpdateEvaluationModelItemUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(
    teacherId: string,
    evaluationModelId: string,
    itemId: string,
    input: {
      name?: string;
      maxScore?: number;
      sortOrder?: number;
      isRecovery?: boolean;
      recoversItemId?: string | null;
    },
  ): Promise<EvaluationModelItem> {
    const model = await this.models.findById(teacherId, evaluationModelId);
    if (!model) {
      throw new NotFoundError('Evaluation model not found');
    }

    const item = await this.models.findItemById(teacherId, itemId);
    if (!item || item.evaluationModelId !== evaluationModelId) {
      throw new NotFoundError('Evaluation model item not found');
    }

    if (input.name !== undefined && !input.name.trim()) {
      throw new ValidationError('Evaluation model item name is required');
    }
    if (input.maxScore !== undefined && input.maxScore <= 0) {
      throw new ValidationError('Item maxScore must be greater than zero');
    }

    const isRecovery = input.isRecovery ?? item.isRecovery;
    const recoversItemId =
      input.isRecovery === false
        ? null
        : (input.recoversItemId !== undefined ? input.recoversItemId : item.recoversItemId);

    assertRecoveryLink({
      isRecovery,
      recoversItemId,
      itemId,
      modelItems: model.items,
    });

    return this.models.updateItem(teacherId, itemId, {
      ...(input.name !== undefined ? { name: input.name.trim() } : {}),
      ...(input.maxScore !== undefined ? { maxScore: input.maxScore } : {}),
      ...(input.sortOrder !== undefined ? { sortOrder: input.sortOrder } : {}),
      isRecovery,
      recoversItemId,
    });
  }
}
