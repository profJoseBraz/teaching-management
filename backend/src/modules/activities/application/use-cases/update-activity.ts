import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Activity } from '../../domain/activity';
import type { ActivityRepository, UpdateActivityInput } from '../ports/activity-repository';

export class UpdateActivityUseCase {
  constructor(private readonly activities: ActivityRepository) {}

  async execute(id: string, teacherId: string, patch: UpdateActivityInput): Promise<Activity> {
    const existing = await this.activities.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Activity not found');
    }

    if (patch.maxScore !== undefined && patch.maxScore <= 0) {
      throw new ValidationError('maxScore must be greater than zero');
    }

    return this.activities.update(id, teacherId, patch);
  }
}
