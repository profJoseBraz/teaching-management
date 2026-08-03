import type { AssessmentPeriod } from '../../domain/assessment-period';

export type CreateAssessmentPeriodInput = {
  teacherId: string;
  academicYearId: string;
  classId?: string | null;
  name: string;
  startsOn?: Date | null;
  endsOn?: Date | null;
};

export type UpdateAssessmentPeriodInput = Partial<{
  name: string;
  classId: string | null;
  startsOn: Date | null;
  endsOn: Date | null;
}>;

export interface AssessmentPeriodRepository {
  create(input: CreateAssessmentPeriodInput): Promise<AssessmentPeriod>;
  findById(teacherId: string, id: string): Promise<AssessmentPeriod | null>;
  listByAcademicYear(teacherId: string, academicYearId: string): Promise<AssessmentPeriod[]>;
  countByAcademicYear(teacherId: string, academicYearId: string): Promise<number>;
  update(teacherId: string, id: string, input: UpdateAssessmentPeriodInput): Promise<AssessmentPeriod>;
  /** Aplica a nova ordem (posição no array => sortOrder) atomicamente. */
  reorder(teacherId: string, academicYearId: string, orderedIds: string[]): Promise<AssessmentPeriod[]>;
}
