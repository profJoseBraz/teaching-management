import { NotFoundError } from '../../../../shared/domain/errors';
import type { Student } from '../../domain/student';
import type { StudentRepository, UpdateStudentInput } from '../ports/student-repository';

export class UpdateStudentUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(teacherId: string, id: string, input: UpdateStudentInput): Promise<Student> {
    const existing = await this.students.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Student not found');
    }

    return this.students.update(teacherId, id, input);
  }
}
