import type { Discipline } from '../../domain/discipline';
import type { DisciplineRepository } from '../ports/discipline-repository';

export class ListDisciplinesUseCase {
  constructor(private readonly disciplines: DisciplineRepository) {}

  async execute(teacherId: string): Promise<Discipline[]> {
    return this.disciplines.list(teacherId);
  }
}
