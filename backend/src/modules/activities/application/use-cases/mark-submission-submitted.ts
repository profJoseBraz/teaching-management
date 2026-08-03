import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Submission } from '../../domain/submission';
import type { SubmissionRepository } from '../ports/submission-repository';

export class MarkSubmissionSubmittedUseCase {
  constructor(private readonly submissions: SubmissionRepository) {}

  async execute(submissionId: string, teacherId: string): Promise<Submission> {
    const submission = await this.submissions.findById(submissionId, teacherId);
    if (!submission) {
      throw new NotFoundError('Submission not found');
    }

    if (submission.status === 'GRADED') {
      throw new ValidationError('Cannot mark a graded submission as submitted');
    }

    if (submission.status === 'SUBMITTED') {
      return submission;
    }

    return this.submissions.updateStatus(submissionId, teacherId, 'SUBMITTED', new Date());
  }
}
