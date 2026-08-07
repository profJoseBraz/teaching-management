import { NotFoundError } from '../../../../shared/domain/errors';
import type { EvaluationModel } from '../../domain/evaluation-model';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export class DeactivateEvaluationModelUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(teacherId: string, id: string): Promise<EvaluationModel> {
    const existing = await this.models.findById(teacherId, id);
    if (!existing) {
      throw new NotFoundError('Evaluation model not found');
    }
    return this.models.update(teacherId, id, { isActive: false });
  }
}
