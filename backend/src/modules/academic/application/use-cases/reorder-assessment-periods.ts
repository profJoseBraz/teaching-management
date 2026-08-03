import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { AssessmentPeriod } from '../../domain/assessment-period';
import type { AcademicYearRepository } from '../ports/academic-year-repository';
import type { AssessmentPeriodRepository } from '../ports/assessment-period-repository';

export type ReorderAssessmentPeriodsInput = {
  teacherId: string;
  academicYearId: string;
  orderedIds: string[];
};

/** Reordena os períodos avaliativos de um ano letivo a partir da lista de ids na nova ordem. */
export class ReorderAssessmentPeriodsUseCase {
  constructor(
    private readonly assessmentPeriods: AssessmentPeriodRepository,
    private readonly academicYears: AcademicYearRepository,
  ) {}

  async execute(input: ReorderAssessmentPeriodsInput): Promise<AssessmentPeriod[]> {
    const academicYear = await this.academicYears.findById(input.teacherId, input.academicYearId);
    if (!academicYear || academicYear.deletedAt) {
      throw new NotFoundError('Academic year not found');
    }

    const existing = await this.assessmentPeriods.listByAcademicYear(
      input.teacherId,
      input.academicYearId,
    );

    const existingIds = new Set(existing.map((period) => period.id));
    const uniqueOrderedIds = new Set(input.orderedIds);

    if (
      uniqueOrderedIds.size !== input.orderedIds.length ||
      uniqueOrderedIds.size !== existingIds.size ||
      ![...uniqueOrderedIds].every((id) => existingIds.has(id))
    ) {
      throw new ValidationError('orderedIds must match exactly the assessment periods of this academic year');
    }

    return this.assessmentPeriods.reorder(input.teacherId, input.academicYearId, input.orderedIds);
  }
}
