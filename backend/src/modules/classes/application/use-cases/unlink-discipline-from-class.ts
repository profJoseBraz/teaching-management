import { NotFoundError } from '../../../../shared/domain/errors';
import type { ClassDisciplineRepository } from '../ports/class-discipline-repository';

export class UnlinkDisciplineFromClassUseCase {
  constructor(private readonly classDisciplines: ClassDisciplineRepository) {}

  async execute(teacherId: string, classId: string, disciplineId: string): Promise<void> {
    const link = await this.classDisciplines.findLink(teacherId, classId, disciplineId);
    if (!link || link.deletedAt) {
      throw new NotFoundError('Discipline is not linked to this class');
    }

    await this.classDisciplines.softDeleteLink(teacherId, classId, disciplineId);
  }
}
