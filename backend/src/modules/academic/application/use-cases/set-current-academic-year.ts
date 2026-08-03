import { NotFoundError } from '../../../../shared/domain/errors';
import type { AcademicYear } from '../../domain/academic-year';
import type { AcademicYearRepository } from '../ports/academic-year-repository';

/** Garante que apenas um ano letivo do professor fique marcado como atual. */
export class SetCurrentAcademicYearUseCase {
  constructor(private readonly academicYears: AcademicYearRepository) {}

  async execute(teacherId: string, id: string): Promise<AcademicYear> {
    const existing = await this.academicYears.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Academic year not found');
    }

    return this.academicYears.setCurrent(teacherId, id);
  }
}
