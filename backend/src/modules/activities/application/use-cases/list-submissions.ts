import { NotFoundError } from '../../../../shared/domain/errors';
import type { Submission } from '../../domain/submission';
import type { ActivityRepository } from '../ports/activity-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

export class ListSubmissionsUseCase {
  constructor(
    private readonly activities: ActivityRepository,
    private readonly submissions: SubmissionRepository,
  ) {}

  async execute(activityId: string, teacherId: string): Promise<Submission[]> {
    const activity = await this.activities.findById(activityId, teacherId);
    if (!activity) {
      throw new NotFoundError('Activity not found');
    }

    return this.submissions.listByActivity(activityId, teacherId);
  }
}
