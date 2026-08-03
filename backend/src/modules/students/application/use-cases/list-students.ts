import type { Student } from '../../domain/student';
import type { ListStudentsFilters, StudentRepository } from '../ports/student-repository';

export class ListStudentsUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(teacherId: string, filters?: ListStudentsFilters): Promise<Student[]> {
    return this.students.list(teacherId, filters);
  }
}
