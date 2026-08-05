import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Submission } from '../../domain/submission';
import type { ActivityRepository } from '../ports/activity-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

const MAX_BULK_GRADE = 200;

/**
 * Atribui a mesma nota a várias entregas da atividade (seleção livre do professor).
 * Independente de mode/group — útil quando vários alunos tiraram a mesma nota.
 */
export class GradeSubmissionsBulkUseCase {
  constructor(
    private readonly submissions: SubmissionRepository,
    private readonly activities: ActivityRepository,
  ) {}

  async execute(
    activityId: string,
    teacherId: string,
    submissionIds: string[],
    score: number,
    observations?: string | null,
  ): Promise<Submission[]> {
    const activity = await this.activities.findById(activityId, teacherId);
    if (!activity) {
      throw new NotFoundError('Activity not found');
    }

    const uniqueIds = [...new Set(submissionIds)];
    if (uniqueIds.length === 0) {
      throw new ValidationError('At least one submissionId is required');
    }
    if (uniqueIds.length > MAX_BULK_GRADE) {
      throw new ValidationError(`Cannot grade more than ${MAX_BULK_GRADE} submissions at once`);
    }

    if (score < 0 || score > activity.maxScore) {
      throw new ValidationError(`score must be between 0 and ${activity.maxScore}`);
    }

    const found = await this.submissions.findByIds(uniqueIds, teacherId);
    if (found.length !== uniqueIds.length) {
      throw new ValidationError('One or more submissions were not found');
    }

    const foreign = found.find((s) => s.activityId !== activityId);
    if (foreign) {
      throw new ValidationError('All submissions must belong to the informed activity');
    }

    return this.submissions.gradeMany(uniqueIds, teacherId, score, observations ?? null);
  }
}
