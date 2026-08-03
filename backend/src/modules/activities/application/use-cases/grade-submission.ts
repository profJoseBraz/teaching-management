import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Submission } from '../../domain/submission';
import type { ActivityRepository } from '../ports/activity-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

export class GradeSubmissionUseCase {
  constructor(
    private readonly submissions: SubmissionRepository,
    private readonly activities: ActivityRepository,
  ) {}

  async execute(
    submissionId: string,
    teacherId: string,
    score: number,
    observations?: string | null,
  ): Promise<Submission> {
    const submission = await this.submissions.findById(submissionId, teacherId);
    if (!submission) {
      throw new NotFoundError('Submission not found');
    }

    const activity = await this.activities.findById(submission.activityId, teacherId);
    if (!activity) {
      throw new NotFoundError('Activity not found');
    }

    if (score < 0 || score > activity.maxScore) {
      throw new ValidationError(`score must be between 0 and ${activity.maxScore}`);
    }

    return this.submissions.grade(submissionId, teacherId, score, observations ?? null);
  }
}
