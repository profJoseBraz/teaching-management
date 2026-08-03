import type { EnrollmentGateway } from '../../../../shared/application/ports/enrollment-gateway';
import type { LessonGateway } from '../../../../shared/application/ports/lesson-gateway';
import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { AttendanceSheet } from '../../domain/attendance';
import type { AttendanceRepository } from '../ports/attendance-repository';
import { GetAttendanceSheetUseCase } from './get-attendance-sheet';

/**
 * Decisão de design: CompleteAttendance exige que TODOS os alunos com matrícula
 * ativa já possuam registro de chamada (via SaveAttendance) antes de concluir.
 * Se houver pendências, lança ValidationError listando os alunos faltantes —
 * não preenche automaticamente como PRESENT, evitando mascarar esquecimentos.
 */
export class CompleteAttendanceUseCase {
  constructor(
    private readonly attendances: AttendanceRepository,
    private readonly lessons: LessonGateway,
    private readonly enrollments: EnrollmentGateway,
    private readonly getAttendanceSheetUseCase: GetAttendanceSheetUseCase,
  ) {}

  async execute(lessonId: string, teacherId: string): Promise<AttendanceSheet> {
    const lesson = await this.lessons.findById(lessonId, teacherId);
    if (!lesson) {
      throw new NotFoundError('Lesson not found');
    }

    const [activeStudents, records] = await Promise.all([
      this.enrollments.listActiveStudents(lesson.classId),
      this.attendances.listByLesson(lessonId, teacherId),
    ]);

    const recordedStudentIds = new Set(records.map((record) => record.studentId));
    const missing = activeStudents.filter((student) => !recordedStudentIds.has(student.studentId));

    if (missing.length > 0) {
      throw new ValidationError('All active students must have attendance recorded before completing', {
        missingStudents: missing,
      });
    }

    await this.lessons.markAttendanceCompleted(lessonId);

    return this.getAttendanceSheetUseCase.execute(lessonId, teacherId);
  }
}
