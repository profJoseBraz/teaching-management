import { NotFoundError } from '../../../../shared/domain/errors';
import type { AcademicYear } from '../../domain/academic-year';
import type { AcademicYearRepository, UpdateAcademicYearInput } from '../ports/academic-year-repository';

export class UpdateAcademicYearUseCase {
  constructor(private readonly academicYears: AcademicYearRepository) {}

  async execute(teacherId: string, id: string, input: UpdateAcademicYearInput): Promise<AcademicYear> {
    const existing = await this.academicYears.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Academic year not found');
    }

    return this.academicYears.update(teacherId, id, input);
  }
}
