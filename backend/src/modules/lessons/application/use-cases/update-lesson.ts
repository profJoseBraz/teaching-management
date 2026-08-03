import { NotFoundError } from '../../../../shared/domain/errors';
import { assertEndTimeAfterStartTime } from '../../domain/lesson-time';
import type { Lesson } from '../../domain/lesson';
import type { LessonRepository, UpdateLessonInput } from '../ports/lesson-repository';

export class UpdateLessonUseCase {
  constructor(private readonly lessons: LessonRepository) {}

  async execute(id: string, teacherId: string, patch: UpdateLessonInput): Promise<Lesson> {
    const existing = await this.lessons.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Lesson not found');
    }

    const startTime = patch.startTime ?? existing.startTime;
    const endTime = patch.endTime ?? existing.endTime;
    assertEndTimeAfterStartTime(startTime, endTime);

    return this.lessons.update(id, teacherId, patch);
  }
}
