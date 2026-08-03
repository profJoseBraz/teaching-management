import { NotFoundError } from '../../../../shared/domain/errors';
import type { ClassDisciplineDetail } from '../../domain/class-discipline';
import type { ClassDisciplineRepository } from '../ports/class-discipline-repository';
import type { ClassRepository } from '../ports/class-repository';

export class ListClassDisciplinesUseCase {
  constructor(
    private readonly classes: ClassRepository,
    private readonly classDisciplines: ClassDisciplineRepository,
  ) {}

  async execute(teacherId: string, classId: string): Promise<ClassDisciplineDetail[]> {
    const klass = await this.classes.findById(teacherId, classId);
    if (!klass || klass.deletedAt) {
      throw new NotFoundError('Class not found');
    }

    return this.classDisciplines.listByClass(teacherId, classId);
  }
}
