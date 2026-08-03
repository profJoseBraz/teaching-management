import { NotFoundError } from '../../../../shared/domain/errors';
import type { AssessmentPeriod } from '../../domain/assessment-period';
import type { AcademicYearRepository } from '../ports/academic-year-repository';
import type { AssessmentPeriodRepository } from '../ports/assessment-period-repository';

export class ListAssessmentPeriodsUseCase {
  constructor(
    private readonly assessmentPeriods: AssessmentPeriodRepository,
    private readonly academicYears: AcademicYearRepository,
  ) {}

  async execute(teacherId: string, academicYearId: string): Promise<AssessmentPeriod[]> {
    const academicYear = await this.academicYears.findById(teacherId, academicYearId);
    if (!academicYear || academicYear.deletedAt) {
      throw new NotFoundError('Academic year not found');
    }

    return this.assessmentPeriods.listByAcademicYear(teacherId, academicYearId);
  }
}
