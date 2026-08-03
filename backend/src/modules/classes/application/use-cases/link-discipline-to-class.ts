import { ConflictError, NotFoundError } from '../../../../shared/domain/errors';
import type { DisciplineRepository } from '../../../academic/application/ports/discipline-repository';
import type { ClassDiscipline } from '../../domain/class-discipline';
import type { ClassDisciplineRepository } from '../ports/class-discipline-repository';
import type { ClassRepository } from '../ports/class-repository';

export type LinkDisciplineToClassInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
};

/** Vincula uma disciplina adicional a uma turma já existente. */
export class LinkDisciplineToClassUseCase {
  constructor(
    private readonly classDisciplines: ClassDisciplineRepository,
    private readonly classes: ClassRepository,
    private readonly disciplines: DisciplineRepository,
  ) {}

  async execute(input: LinkDisciplineToClassInput): Promise<ClassDiscipline> {
    const klass = await this.classes.findById(input.teacherId, input.classId);
    if (!klass || klass.deletedAt) {
      throw new NotFoundError('Class not found');
    }

    const discipline = await this.disciplines.findById(input.teacherId, input.disciplineId);
    if (!discipline || discipline.deletedAt) {
      throw new NotFoundError('Discipline not found');
    }

    const existingLink = await this.classDisciplines.findLink(
      input.teacherId,
      input.classId,
      input.disciplineId,
    );

    if (existingLink) {
      if (!existingLink.deletedAt) {
        throw new ConflictError('Discipline already linked to this class');
      }
      return this.classDisciplines.reactivate(input.teacherId, existingLink.id);
    }

    return this.classDisciplines.create(input);
  }
}
