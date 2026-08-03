import { NotFoundError } from '../../../../shared/domain/errors';
import type { ClassWithDisciplines } from '../../domain/class';
import type { ClassDisciplineRepository } from '../ports/class-discipline-repository';
import type { ClassRepository } from '../ports/class-repository';

/** Arquiva a turma (status ARCHIVED) preservando todo o histórico associado. */
export class ArchiveClassUseCase {
  constructor(
    private readonly classes: ClassRepository,
    private readonly classDisciplines: ClassDisciplineRepository,
  ) {}

  async execute(teacherId: string, id: string): Promise<ClassWithDisciplines> {
    const existing = await this.classes.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Class not found');
    }

    const archived = await this.classes.archive(teacherId, id);
    const links = await this.classDisciplines.listByClass(teacherId, id);

    return {
      ...archived,
      disciplineIds: links.map((link) => link.disciplineId),
      disciplines: links.map((link) => ({ id: link.discipline.id, name: link.discipline.name })),
    };
  }
}
