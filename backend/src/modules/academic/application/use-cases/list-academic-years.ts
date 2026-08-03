import type { AcademicYear } from '../../domain/academic-year';
import type { AcademicYearRepository } from '../ports/academic-year-repository';

export class ListAcademicYearsUseCase {
  constructor(private readonly academicYears: AcademicYearRepository) {}

  async execute(teacherId: string): Promise<AcademicYear[]> {
    return this.academicYears.list(teacherId);
  }
}
