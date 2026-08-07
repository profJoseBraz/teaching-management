import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { EvaluationModelItem } from '../../domain/evaluation-model';
import { assertRecoveryLink } from '../assert-recovery-link';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export class CreateEvaluationModelItemUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(input: {
    teacherId: string;
    evaluationModelId: string;
    name: string;
    maxScore: number;
    sortOrder?: number;
    isRecovery?: boolean;
    recoversItemId?: string | null;
  }): Promise<EvaluationModelItem> {
    const model = await this.models.findById(input.teacherId, input.evaluationModelId);
    if (!model) {
      throw new NotFoundError('Evaluation model not found');
    }

    const name = input.name.trim();
    if (!name) {
      throw new ValidationError('Evaluation model item name is required');
    }
    if (input.maxScore <= 0) {
      throw new ValidationError('Item maxScore must be greater than zero');
    }

    const isRecovery = input.isRecovery ?? false;
    assertRecoveryLink({
      isRecovery,
      recoversItemId: input.recoversItemId,
      modelItems: model.items,
    });

    return this.models.createItem({
      teacherId: input.teacherId,
      evaluationModelId: input.evaluationModelId,
      name,
      maxScore: input.maxScore,
      sortOrder: input.sortOrder,
      isRecovery,
      recoversItemId: isRecovery ? input.recoversItemId : null,
    });
  }
}
