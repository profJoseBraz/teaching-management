import { NotFoundError } from '../../../../shared/domain/errors';
import type { Lesson } from '../../domain/lesson';
import type { LessonRepository } from '../ports/lesson-repository';

export class GetLessonUseCase {
  constructor(private readonly lessons: LessonRepository) {}

  async execute(id: string, teacherId: string): Promise<Lesson> {
    const lesson = await this.lessons.findById(id, teacherId);
    if (!lesson) {
      throw new NotFoundError('Lesson not found');
    }
    return lesson;
  }
}
