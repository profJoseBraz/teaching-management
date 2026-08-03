import type { Student } from '../../domain/student';
import type { CreateStudentInput, StudentRepository } from '../ports/student-repository';

export class CreateStudentUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(input: CreateStudentInput): Promise<Student> {
    return this.students.create(input);
  }
}
