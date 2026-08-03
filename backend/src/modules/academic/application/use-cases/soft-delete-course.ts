import { NotFoundError } from '../../../../shared/domain/errors';
import type { CourseRepository } from '../ports/course-repository';

/** Arquiva o curso via soft delete, preservando o histórico de turmas vinculadas. */
export class SoftDeleteCourseUseCase {
  constructor(private readonly courses: CourseRepository) {}

  async execute(teacherId: string, id: string): Promise<void> {
    const existing = await this.courses.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Course not found');
    }

    await this.courses.softDelete(teacherId, id);
  }
}
