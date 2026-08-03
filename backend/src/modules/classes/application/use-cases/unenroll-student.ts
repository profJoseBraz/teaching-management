import { NotFoundError } from '../../../../shared/domain/errors';
import type { EnrollmentRepository } from '../ports/enrollment-repository';

/** Encerra a matrícula do aluno na turma (status WITHDRAWN), preservando histórico de frequência/notas. */
export class UnenrollStudentUseCase {
  constructor(private readonly enrollments: EnrollmentRepository) {}

  async execute(teacherId: string, classId: string, studentId: string): Promise<void> {
    const existing = await this.enrollments.findByClassAndStudent(teacherId, classId, studentId);
    if (!existing || existing.deletedAt || existing.status === 'WITHDRAWN') {
      throw new NotFoundError('Active enrollment not found');
    }

    await this.enrollments.withdraw(teacherId, classId, studentId);
  }
}
