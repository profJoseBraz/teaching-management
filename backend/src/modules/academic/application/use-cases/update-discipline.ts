import { ConflictError, NotFoundError } from '../../../../shared/domain/errors';
import type { Discipline } from '../../domain/discipline';
import type { DisciplineRepository, UpdateDisciplineInput } from '../ports/discipline-repository';

export class UpdateDisciplineUseCase {
  constructor(private readonly disciplines: DisciplineRepository) {}

  async execute(teacherId: string, id: string, input: UpdateDisciplineInput): Promise<Discipline> {
    const existing = await this.disciplines.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Discipline not found');
    }

    if (input.name && input.name !== existing.name) {
      const withSameName = await this.disciplines.findByName(teacherId, input.name);
      if (withSameName && !withSameName.deletedAt && withSameName.id !== id) {
        throw new ConflictError('Discipline already exists for this teacher');
      }
    }

    return this.disciplines.update(teacherId, id, input);
  }
}
