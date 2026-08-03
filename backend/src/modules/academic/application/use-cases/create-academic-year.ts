import { ConflictError } from '../../../../shared/domain/errors';
import type { AcademicYear } from '../../domain/academic-year';
import type { AcademicYearRepository, CreateAcademicYearInput } from '../ports/academic-year-repository';

export class CreateAcademicYearUseCase {
  constructor(private readonly academicYears: AcademicYearRepository) {}

  async execute(input: CreateAcademicYearInput): Promise<AcademicYear> {
    const existing = await this.academicYears.findByYear(input.teacherId, input.year);
    if (existing) {
      throw new ConflictError('Academic year already exists for this teacher');
    }

    return this.academicYears.create(input);
  }
}
