import { ValidationError } from '../../../../shared/domain/errors';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import type { Lesson } from '../../domain/lesson';
import type { LessonRepository, ListLessonsFilters } from '../ports/lesson-repository';

export class ListLessonsUseCase {
  constructor(
    private readonly lessons: LessonRepository,
    private readonly classOwnership: ClassOwnershipChecker,
  ) {}

  async execute(
    classId: string,
    teacherId: string,
    filters: ListLessonsFilters = {},
  ): Promise<Lesson[]> {
    const owned = await this.classOwnership.isOwnedByTeacher(classId, teacherId);
    if (!owned) {
      throw new ValidationError('Class not found for this teacher');
    }

    return this.lessons.listByClass(classId, teacherId, filters);
  }
}
