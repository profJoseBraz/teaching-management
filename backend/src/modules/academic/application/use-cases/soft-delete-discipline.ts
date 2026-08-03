import { NotFoundError } from '../../../../shared/domain/errors';
import type { DisciplineRepository } from '../ports/discipline-repository';

export class SoftDeleteDisciplineUseCase {
  constructor(private readonly disciplines: DisciplineRepository) {}

  async execute(teacherId: string, id: string): Promise<void> {
    const existing = await this.disciplines.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Discipline not found');
    }

    await this.disciplines.softDelete(teacherId, id);
  }
}
