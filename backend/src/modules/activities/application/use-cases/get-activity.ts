import { NotFoundError } from '../../../../shared/domain/errors';
import type { Activity } from '../../domain/activity';
import type { Submission } from '../../domain/submission';
import type { ActivityRepository } from '../ports/activity-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

export type SubmissionsSummary = {
  total: number;
  pending: number;
  submitted: number;
  graded: number;
  averageScore: number | null;
};

export type GetActivityOutput = {
  activity: Activity;
  submissions: Submission[];
  summary: SubmissionsSummary;
};

function buildSummary(submissions: Submission[]): SubmissionsSummary {
  const gradedScores = submissions
    .filter((submission) => submission.status === 'GRADED' && submission.score !== null)
    .map((submission) => submission.score as number);

  const averageScore =
    gradedScores.length > 0
      ? gradedScores.reduce((sum, score) => sum + score, 0) / gradedScores.length
      : null;

  return {
    total: submissions.length,
    pending: submissions.filter((submission) => submission.status === 'PENDING').length,
    submitted: submissions.filter((submission) => submission.status === 'SUBMITTED').length,
    graded: submissions.filter((submission) => submission.status === 'GRADED').length,
    averageScore,
  };
}

export class GetActivityUseCase {
  constructor(
    private readonly activities: ActivityRepository,
    private readonly submissions: SubmissionRepository,
  ) {}

  async execute(id: string, teacherId: string): Promise<GetActivityOutput> {
    const activity = await this.activities.findById(id, teacherId);
    if (!activity) {
      throw new NotFoundError('Activity not found');
    }

    const submissions = await this.submissions.listByActivity(id, teacherId);

    return {
      activity,
      submissions,
      summary: buildSummary(submissions),
    };
  }
}
