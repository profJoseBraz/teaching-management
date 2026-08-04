import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import { ValidationError } from '../../../../shared/domain/errors';
import type { Activity } from '../../domain/activity';
import type { ActivityRepository } from '../ports/activity-repository';

export class ListActivitiesUseCase {
  constructor(
    private readonly activities: ActivityRepository,
    private readonly classOwnership: ClassOwnershipChecker,
  ) {}

  async execute(
    classId: string,
    teacherId: string,
    filters: { disciplineId?: string; tag?: string } = {},
  ): Promise<Activity[]> {
    const owned = await this.classOwnership.isOwnedByTeacher(classId, teacherId);
    if (!owned) {
      throw new ValidationError('Class not found for this teacher');
    }

    return this.activities.listByClass(classId, teacherId, filters);
  }
}
