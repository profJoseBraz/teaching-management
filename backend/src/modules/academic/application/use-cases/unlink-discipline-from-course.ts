import { NotFoundError } from '../../../../shared/domain/errors';
import type { CourseDisciplineRepository } from '../ports/course-discipline-repository';

export class UnlinkDisciplineFromCourseUseCase {
  constructor(private readonly courseDisciplines: CourseDisciplineRepository) {}

  async execute(teacherId: string, courseId: string, disciplineId: string): Promise<void> {
    const link = await this.courseDisciplines.findLink(teacherId, courseId, disciplineId);
    if (!link || link.deletedAt) {
      throw new NotFoundError('Discipline is not linked to this course');
    }

    await this.courseDisciplines.softDeleteLink(teacherId, courseId, disciplineId);
  }
}
