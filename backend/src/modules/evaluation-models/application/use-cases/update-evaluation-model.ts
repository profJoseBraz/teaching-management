import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { EvaluationModel } from '../../domain/evaluation-model';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

export class UpdateEvaluationModelUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(
    teacherId: string,
    id: string,
    input: {
      name?: string;
      description?: string | null;
      isActive?: boolean;
      sortOrder?: number;
    },
  ): Promise<EvaluationModel> {
    const existing = await this.models.findById(teacherId, id);
    if (!existing) {
      throw new NotFoundError('Evaluation model not found');
    }

    if (input.name !== undefined && !input.name.trim()) {
      throw new ValidationError('Evaluation model name is required');
    }

    return this.models.update(teacherId, id, {
      ...(input.name !== undefined ? { name: input.name.trim() } : {}),
      ...(input.description !== undefined
        ? { description: input.description?.trim() || null }
        : {}),
      ...(input.isActive !== undefined ? { isActive: input.isActive } : {}),
      ...(input.sortOrder !== undefined ? { sortOrder: input.sortOrder } : {}),
    });
  }
}
