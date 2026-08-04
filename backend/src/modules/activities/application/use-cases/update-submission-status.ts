import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Submission, SubmissionStatus } from '../../domain/submission';
import type { SubmissionRepository } from '../ports/submission-repository';

export type UpdatableSubmissionStatus = Extract<SubmissionStatus, 'PENDING' | 'SUBMITTED'>;

/**
 * Atualiza o status da entrega entre PENDING e SUBMITTED.
 * GRADED não pode ser alterado por este fluxo (use a avaliação).
 * SUBMITTED → PENDING permite corrigir marcação acidental de “entregue”.
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

    if (submission.status === 'GRADED') {
      throw new ValidationError('Cannot change status of a graded submission');
    }

    if (submission.status === status) {
      return submission;
    }

    if (status === 'SUBMITTED') {
      return this.submissions.updateStatus(submissionId, teacherId, 'SUBMITTED', new Date());
    }

    // PENDING — limpa submittedAt
    return this.submissions.updateStatus(submissionId, teacherId, 'PENDING', null);
  }
}
