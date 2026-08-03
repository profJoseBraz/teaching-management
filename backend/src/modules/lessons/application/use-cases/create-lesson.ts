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

    assertEndTimeAfterStartTime(input.startTime, input.endTime);

    return this.lessons.create({
      teacherId: input.teacherId,
      classId: input.classId,
      disciplineId: input.disciplineId,
      date: input.date,
      startTime: input.startTime,
      endTime: input.endTime,
      observations: input.observations ?? null,
    });
  }
}
