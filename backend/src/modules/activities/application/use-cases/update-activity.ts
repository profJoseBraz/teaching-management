import type { ClassDisciplineGateway } from '../../../../shared/application/ports/class-discipline-gateway';
import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Activity } from '../../domain/activity';
import type { ActivityRepository, UpdateActivityInput } from '../ports/activity-repository';

export class UpdateActivityUseCase {
  constructor(
    private readonly activities: ActivityRepository,
    private readonly classDisciplines: ClassDisciplineGateway,
  ) {}

  async execute(id: string, teacherId: string, patch: UpdateActivityInput): Promise<Activity> {
    const existing = await this.activities.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Activity not found');
    }

    if (patch.maxScore !== undefined && patch.maxScore <= 0) {
      throw new ValidationError('maxScore must be greater than zero');
    }

    if (patch.disciplineIds !== undefined) {
      const disciplineIds = [...new Set(patch.disciplineIds)];
      if (disciplineIds.length === 0) {
        throw new ValidationError('At least one disciplineId is required');
      }

      const allLinked = await this.classDisciplines.areAllLinked(
        teacherId,
        existing.classId,
        disciplineIds,
      );
      if (!allLinked) {
        throw new ValidationError('One or more disciplines are not linked to this class');
      }

      patch = { ...patch, disciplineIds };
    }

    return this.activities.update(id, teacherId, patch);
  }
}
