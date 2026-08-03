import { NotFoundError } from '../../../../shared/domain/errors';
import type { AssessmentPeriod } from '../../domain/assessment-period';
import type { AcademicYearRepository } from '../ports/academic-year-repository';
import type {
  AssessmentPeriodRepository,
  CreateAssessmentPeriodInput,
} from '../ports/assessment-period-repository';

export class CreateAssessmentPeriodUseCase {
  constructor(
    private readonly assessmentPeriods: AssessmentPeriodRepository,
    private readonly academicYears: AcademicYearRepository,
  ) {}

  async execute(input: CreateAssessmentPeriodInput): Promise<AssessmentPeriod> {
    const academicYear = await this.academicYears.findById(input.teacherId, input.academicYearId);
    if (!academicYear || academicYear.deletedAt) {
      throw new NotFoundError('Academic year not found');
    }

    return this.assessmentPeriods.create(input);
  }
}
