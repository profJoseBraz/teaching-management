import type { AssessmentPeriodGateway } from '../../../../shared/application/ports/assessment-period-gateway';
import type { ClassDisciplineGateway } from '../../../../shared/application/ports/class-discipline-gateway';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import { ValidationError } from '../../../../shared/domain/errors';
import { assertEndTimeAfterStartTime } from '../../domain/lesson-time';
import type { Lesson } from '../../domain/lesson';
import type { LessonRepository } from '../ports/lesson-repository';

export type CreateLessonInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
  assessmentPeriodId: string;
  date: Date;
  startTime: string;
  endTime: string;
  observations?: string | null;
};

export class CreateLessonUseCase {
  constructor(
    private readonly lessons: LessonRepository,
    private readonly classOwnership: ClassOwnershipChecker,
    private readonly classDisciplines: ClassDisciplineGateway,
    private readonly assessmentPeriods: AssessmentPeriodGateway,
  ) {}

  async execute(input: CreateLessonInput): Promise<Lesson> {
    const owned = await this.classOwnership.isOwnedByTeacher(input.classId, input.teacherId);
    if (!owned) {
      throw new ValidationError('Class not found for this teacher');
    }

    const linked = await this.classDisciplines.isLinked(input.teacherId, input.classId, input.disciplineId);
    if (!linked) {
      throw new ValidationError('Discipline is not linked to this class');
    }

    await this.assessmentPeriods.assertUsableForClass({
      teacherId: input.teacherId,
      classId: input.classId,
      assessmentPeriodId: input.assessmentPeriodId,
    });

    assertEndTimeAfterStartTime(input.startTime, input.endTime);

    return this.lessons.create({
      teacherId: input.teacherId,
      classId: input.classId,
      disciplineId: input.disciplineId,
      assessmentPeriodId: input.assessmentPeriodId,
      date: input.date,
      startTime: input.startTime,
      endTime: input.endTime,
      observations: input.observations ?? null,
    });
  }
}
