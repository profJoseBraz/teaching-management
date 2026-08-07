import { ConflictError, NotFoundError } from '../../../../shared/domain/errors';
import type { EvaluationModelRepository } from '../ports/evaluation-model-repository';

/** Soft delete apenas se nenhuma composição ativa usar o modelo. Prefira desativar. */
export class SoftDeleteEvaluationModelUseCase {
  constructor(private readonly models: EvaluationModelRepository) {}

  async execute(teacherId: string, id: string): Promise<void> {
    const existing = await this.models.findById(teacherId, id);
    if (!existing) {
      throw new NotFoundError('Evaluation model not found');
    }

    const usage = await this.models.countActiveCompositions(teacherId, id);
    if (usage > 0) {
      throw new ConflictError(
        'Evaluation model is used by grade compositions; deactivate it instead of deleting',
      );
    }

    await this.models.softDelete(teacherId, id);
  }
}
