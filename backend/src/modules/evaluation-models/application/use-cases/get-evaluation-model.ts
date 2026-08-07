import { NotFoundError } from '../../../../shared/domain/errors';
import type { EvaluationModel } from '../../domain/evaluation-model';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export class GetEvaluationModelUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(teacherId: string, id: string): Promise<EvaluationModel> {
    const model = await this.models.findById(teacherId, id);
    if (!model) {
      throw new NotFoundError('Evaluation model not found');
    }
    return model;
  }
}
