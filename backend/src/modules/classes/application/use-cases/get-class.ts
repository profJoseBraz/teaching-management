import { NotFoundError } from '../../../../shared/domain/errors';
import type { ClassWithDisciplines } from '../../domain/class';
import type { ClassDisciplineRepository } from '../ports/class-discipline-repository';
import type { ClassRepository } from '../ports/class-repository';

export class GetClassUseCase {
  constructor(
    private readonly classes: ClassRepository,
    private readonly classDisciplines: ClassDisciplineRepository,
  ) {}

  async execute(teacherId: string, id: string): Promise<ClassWithDisciplines> {
    const found = await this.classes.findById(teacherId, id);
    if (!found || found.deletedAt) {
      throw new NotFoundError('Class not found');
    }

    const links = await this.classDisciplines.listByClass(teacherId, id);

    return {
      ...found,
      disciplineIds: links.map((link) => link.disciplineId),
      disciplines: links.map((link) => ({ id: link.discipline.id, name: link.discipline.name })),
    };
  }
}
