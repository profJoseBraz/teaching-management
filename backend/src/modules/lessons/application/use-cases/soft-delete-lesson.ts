import { NotFoundError } from '../../../../shared/domain/errors';
import type { LessonRepository } from '../ports/lesson-repository';

export class SoftDeleteLessonUseCase {
  constructor(private readonly lessons: LessonRepository) {}

  async execute(id: string, teacherId: string): Promise<void> {
    const existing = await this.lessons.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Lesson not found');
    }

    await this.lessons.softDelete(id, teacherId);
  }
}
