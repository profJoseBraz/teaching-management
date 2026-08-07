import type { EvaluationModel } from '../../domain/evaluation-model';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export class ListEvaluationModelsUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(
    teacherId: string,
    filters?: { includeInactive?: boolean },
  ): Promise<EvaluationModel[]> {
    return this.models.list(teacherId, filters);
  }
}
