import type { AssessmentPeriodGateway } from '../../../../shared/application/ports/assessment-period-gateway';
import { NotFoundError } from '../../../../shared/domain/errors';
import type { Content } from '../../domain/content';
import type { ContentRepository, UpdateContentInput } from '../ports/content-repository';

export class UpdateContentUseCase {
  constructor(
    private readonly contents: ContentRepository,
    private readonly assessmentPeriods: AssessmentPeriodGateway,
  ) {}

  async execute(id: string, teacherId: string, patch: UpdateContentInput): Promise<Content> {
    const existing = await this.contents.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Content not found');
    }

    if (patch.assessmentPeriodId !== undefined) {
      await this.assessmentPeriods.assertUsableForClass({
        teacherId,
        classId: existing.classId,
        assessmentPeriodId: patch.assessmentPeriodId,
      });
    }

    return this.contents.update(id, teacherId, patch);
  }
}
