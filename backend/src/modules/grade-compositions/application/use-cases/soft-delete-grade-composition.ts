import { ConflictError, NotFoundError } from '../../../../shared/domain/errors';
import type { GradeCompositionRepository } from '../ports/grade-composition-repository';

export class SoftDeleteGradeCompositionUseCase {
  constructor(private readonly compositions: GradeCompositionRepository) {}

  async execute(teacherId: string, id: string): Promise<void> {
    const existing = await this.compositions.findById(teacherId, id);
    if (!existing) {
      throw new NotFoundError('Grade composition not found');
    }
    if (existing.status === 'FINALIZED') {
      throw new ConflictError('Finalized grade composition cannot be deleted');
    }
    await this.compositions.softDelete(teacherId, id);
  }
}
