import { NotFoundError } from '../../../../shared/domain/errors';
import type { StudentRepository } from '../ports/student-repository';

export class SoftDeleteStudentUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(teacherId: string, id: string): Promise<void> {
    const existing = await this.students.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Student not found');
    }

    await this.students.softDelete(teacherId, id);
  }
}
