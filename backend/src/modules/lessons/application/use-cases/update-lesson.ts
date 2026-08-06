import type { AssessmentPeriodGateway } from '../../../../shared/application/ports/assessment-period-gateway';
import { NotFoundError } from '../../../../shared/domain/errors';
import { assertEndTimeAfterStartTime } from '../../domain/lesson-time';
import type { Lesson } from '../../domain/lesson';
import type { LessonRepository, UpdateLessonInput } from '../ports/lesson-repository';

export class UpdateLessonUseCase {
  constructor(
    private readonly lessons: LessonRepository,
    private readonly assessmentPeriods: AssessmentPeriodGateway,
  ) {}

  async execute(id: string, teacherId: string, patch: UpdateLessonInput): Promise<Lesson> {
    const existing = await this.lessons.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Lesson not found');
    }

    const startTime = patch.startTime ?? existing.startTime;
    const endTime = patch.endTime ?? existing.endTime;
    assertEndTimeAfterStartTime(startTime, endTime);

    if (patch.assessmentPeriodId !== undefined) {
      await this.assessmentPeriods.assertUsableForClass({
        teacherId,
        classId: existing.classId,
        assessmentPeriodId: patch.assessmentPeriodId,
      });
    }

    return this.lessons.update(id, teacherId, patch);
  }
}
