import { ConflictError, NotFoundError } from '../../../../shared/domain/errors';
import type { StudentRepository } from '../../../students/application/ports/student-repository';
import type { Enrollment } from '../../domain/enrollment';
import type { ClassRepository } from '../ports/class-repository';
import type { EnrollmentRepository } from '../ports/enrollment-repository';

export type EnrollStudentInput = {
  teacherId: string;
  classId: string;
  studentId: string;
};

/** Matricula um aluno na turma, reativando matrícula retirada (WITHDRAWN) quando existente. */
export class EnrollStudentUseCase {
  constructor(
    private readonly enrollments: EnrollmentRepository,
    private readonly classes: ClassRepository,
    private readonly students: StudentRepository,
  ) {}

  async execute(input: EnrollStudentInput): Promise<Enrollment> {
    const klass = await this.classes.findById(input.teacherId, input.classId);
    if (!klass || klass.deletedAt) {
      throw new NotFoundError('Class not found');
    }

    const student = await this.students.findById(input.teacherId, input.studentId);
    if (!student || student.deletedAt) {
      throw new NotFoundError('Student not found');
    }

    const existing = await this.enrollments.findByClassAndStudent(
      input.teacherId,
      input.classId,
      input.studentId,
    );

    if (existing) {
      if (existing.status === 'ACTIVE' && !existing.deletedAt) {
        throw new ConflictError('Student is already enrolled in this class');
      }
      return this.enrollments.reactivate(input.teacherId, existing.id);
    }

    return this.enrollments.create(input);
  }
}
