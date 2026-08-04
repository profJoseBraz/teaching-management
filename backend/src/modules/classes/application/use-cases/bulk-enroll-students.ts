import { ConflictError, NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Enrollment } from '../../domain/enrollment';
import { EnrollStudentUseCase } from './enroll-student';

export type BulkEnrollStudentsInput = {
  teacherId: string;
  classId: string;
  studentIds: string[];
};

export type BulkEnrollStudentsOutput = {
  enrolled: Enrollment[];
  skipped: Array<{ studentId: string; reason: string }>;
  totalEnrolled: number;
};

/**
 * Matricula vários alunos na mesma turma.
 * Conflitos (já matriculado) e alunos inexistentes entram em `skipped`
 * sem abortar o lote.
 */
export class BulkEnrollStudentsUseCase {
  constructor(private readonly enrollStudent: EnrollStudentUseCase) {}

  async execute(input: BulkEnrollStudentsInput): Promise<BulkEnrollStudentsOutput> {
    const studentIds = Array.from(new Set(input.studentIds.filter(Boolean)));
    if (studentIds.length === 0) {
      throw new ValidationError('Informe ao menos um aluno para matricular');
    }

    const enrolled: Enrollment[] = [];
    const skipped: BulkEnrollStudentsOutput['skipped'] = [];

    for (const studentId of studentIds) {
      try {
        const enrollment = await this.enrollStudent.execute({
          teacherId: input.teacherId,
          classId: input.classId,
          studentId,
        });
        enrolled.push(enrollment);
      } catch (error) {
        if (error instanceof ConflictError || error instanceof NotFoundError) {
          skipped.push({
            studentId,
            reason: error.message,
          });
          continue;
        }
        throw error;
      }
    }

    if (enrolled.length === 0) {
      throw new ValidationError('Nenhum aluno pôde ser matriculado');
    }

    return {
      enrolled,
      skipped,
      totalEnrolled: enrolled.length,
    };
  }
}
