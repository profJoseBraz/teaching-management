import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Submission, SubmissionStatus } from '../../domain/submission';
import type { SubmissionRepository } from '../ports/submission-repository';

export type UpdatableSubmissionStatus = Extract<SubmissionStatus, 'PENDING' | 'SUBMITTED'>;

/**
 * Atualiza o status da entrega:
 * - PENDING ↔ SUBMITTED
 * - GRADED → PENDING (corrige avaliação lançada por engano; limpa nota)
 * GRADED → SUBMITTED não é permitido por este fluxo.
 */
export class UpdateSubmissionStatusUseCase {
  constructor(private readonly submissions: SubmissionRepository) {}

  async execute(
    submissionId: string,
    teacherId: string,
    status: UpdatableSubmissionStatus,
  ): Promise<Submission> {
    const submission = await this.submissions.findById(submissionId, teacherId);
    if (!submission) {
      throw new NotFoundError('Submission not found');
    }

    if (submission.status === status) {
      return submission;
    }

    if (submission.status === 'GRADED') {
      if (status !== 'PENDING') {
        throw new ValidationError('Graded submissions can only be reverted to PENDING');
      }
      return this.submissions.resetToPending(submissionId, teacherId);
    }

    if (status === 'SUBMITTED') {
      return this.submissions.updateStatus(submissionId, teacherId, 'SUBMITTED', new Date());
    }

    // PENDING a partir de SUBMITTED — limpa submittedAt
    return this.submissions.updateStatus(submissionId, teacherId, 'PENDING', null);
  }
}
