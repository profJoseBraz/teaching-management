import { NotFoundError } from '../../../../shared/domain/errors';
import type { EnrollmentWithStudent } from '../../domain/enrollment';
import type { ClassRepository } from '../ports/class-repository';
import type { EnrollmentRepository } from '../ports/enrollment-repository';

export class ListClassStudentsUseCase {
  constructor(
    private readonly enrollments: EnrollmentRepository,
    private readonly classes: ClassRepository,
  ) {}

  async execute(teacherId: string, classId: string): Promise<EnrollmentWithStudent[]> {
    const klass = await this.classes.findById(teacherId, classId);
    if (!klass || klass.deletedAt) {
      throw new NotFoundError('Class not found');
    }

    return this.enrollments.listByClass(teacherId, classId);
  }
}
