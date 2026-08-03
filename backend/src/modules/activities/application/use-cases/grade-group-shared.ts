import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Submission } from '../../domain/submission';
import type { ActivityGroupRepository } from '../ports/activity-group-repository';
import type { ActivityRepository } from '../ports/activity-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

export class GradeGroupSharedUseCase {
  constructor(
    private readonly submissions: SubmissionRepository,
    private readonly activities: ActivityRepository,
    private readonly activityGroups: ActivityGroupRepository,
  ) {}

  async execute(
    activityId: string,
    groupId: string,
    teacherId: string,
    score: number,
    observations?: string | null,
  ): Promise<Submission[]> {
    const activity = await this.activities.findById(activityId, teacherId);
    if (!activity) {
      throw new NotFoundError('Activity not found');
    }

    if (activity.gradeMode !== 'SHARED') {
      throw new ValidationError('Activity grade mode is not SHARED');
    }

    if (score < 0 || score > activity.maxScore) {
      throw new ValidationError(`score must be between 0 and ${activity.maxScore}`);
    }

    const group = await this.activityGroups.findById(groupId, teacherId);
    if (!group || group.activityId !== activityId) {
      throw new NotFoundError('Group not found for this activity');
    }

    return this.submissions.gradeByGroup(groupId, teacherId, score, observations ?? null);
  }
}
