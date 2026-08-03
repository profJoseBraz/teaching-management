import { NotFoundError } from '../../../../shared/domain/errors';
import type { AssessmentPeriod } from '../../domain/assessment-period';
import type {
  AssessmentPeriodRepository,
  UpdateAssessmentPeriodInput,
} from '../ports/assessment-period-repository';

export class UpdateAssessmentPeriodUseCase {
  constructor(private readonly assessmentPeriods: AssessmentPeriodRepository) {}

  async execute(
    teacherId: string,
    id: string,
    input: UpdateAssessmentPeriodInput,
  ): Promise<AssessmentPeriod> {
    const existing = await this.assessmentPeriods.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Assessment period not found');
    }

    return this.assessmentPeriods.update(teacherId, id, input);
  }
}
