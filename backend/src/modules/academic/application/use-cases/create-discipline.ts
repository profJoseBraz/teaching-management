import { ConflictError } from '../../../../shared/domain/errors';
import type { Discipline } from '../../domain/discipline';
import type { DisciplineRepository, CreateDisciplineInput } from '../ports/discipline-repository';

export class CreateDisciplineUseCase {
  constructor(private readonly disciplines: DisciplineRepository) {}

  async execute(input: CreateDisciplineInput): Promise<Discipline> {
    const existing = await this.disciplines.findByName(input.teacherId, input.name);
    if (existing && !existing.deletedAt) {
      throw new ConflictError('Discipline already exists for this teacher');
    }

    return this.disciplines.create(input);
  }
}
