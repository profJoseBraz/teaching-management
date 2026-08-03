import { NotFoundError } from '../../../../shared/domain/errors';
import type { Student } from '../../domain/student';
import type { StudentRepository } from '../ports/student-repository';

export class GetStudentUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(teacherId: string, id: string): Promise<Student> {
    const student = await this.students.findById(teacherId, id);
    if (!student || student.deletedAt) {
      throw new NotFoundError('Student not found');
    }

    return student;
  }
}
