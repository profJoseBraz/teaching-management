import { NotFoundError } from '../../../../shared/domain/errors';
import type { ClassWithDisciplines } from '../../domain/class';
import type { ClassDisciplineRepository } from '../ports/class-discipline-repository';
import type { ClassRepository, UpdateClassInput } from '../ports/class-repository';

/** Atualiza apenas dados descritivos da turma; ano/curso são imutáveis após criação. */
export class UpdateClassUseCase {
  constructor(
    private readonly classes: ClassRepository,
    private readonly classDisciplines: ClassDisciplineRepository,
  ) {}

  async execute(teacherId: string, id: string, input: UpdateClassInput): Promise<ClassWithDisciplines> {
    const existing = await this.classes.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Class not found');
    }

    const updated = await this.classes.update(teacherId, id, input);
    const links = await this.classDisciplines.listByClass(teacherId, id);

    return {
      ...updated,
      disciplineIds: links.map((link) => link.disciplineId),
      disciplines: links.map((link) => ({ id: link.discipline.id, name: link.discipline.name })),
    };
  }
}
