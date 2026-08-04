import { NotFoundError } from '../../../../shared/domain/errors';
import type { ActivityRepository } from '../ports/activity-repository';

export class SoftDeleteActivityUseCase {
  constructor(private readonly activities: ActivityRepository) {}

  async execute(id: string, teacherId: string): Promise<void> {
    const existing = await this.activities.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Activity not found');
    }

    await this.activities.softDelete(id, teacherId);
  }
}
