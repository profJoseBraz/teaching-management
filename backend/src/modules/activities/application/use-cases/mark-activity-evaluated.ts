import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Activity } from '../../domain/activity';
import type { ActivityRepository } from '../ports/activity-repository';

export class MarkActivityEvaluatedUseCase {
  constructor(private readonly activities: ActivityRepository) {}

  async execute(id: string, teacherId: string): Promise<Activity> {
    const existing = await this.activities.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Activity not found');
    }
    if (existing.evaluated) {
      throw new ValidationError('Activity is already marked as evaluated');
    }
    return this.activities.update(id, teacherId, {
      evaluated: true,
      evaluatedAt: new Date(),
    });
  }
}
