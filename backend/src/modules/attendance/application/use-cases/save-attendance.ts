import type { EnrollmentGateway } from '../../../../shared/application/ports/enrollment-gateway';
import type { LessonGateway } from '../../../../shared/application/ports/lesson-gateway';
import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { AttendanceSheet } from '../../domain/attendance';
import type { AttendanceRepository, UpsertAttendanceInput } from '../ports/attendance-repository';
import { GetAttendanceSheetUseCase } from './get-attendance-sheet';

export class SaveAttendanceUseCase {
  constructor(
    private readonly attendances: AttendanceRepository,
    private readonly lessons: LessonGateway,
    private readonly enrollments: EnrollmentGateway,
    private readonly getAttendanceSheetUseCase: GetAttendanceSheetUseCase,
  ) {}

  async execute(
    lessonId: string,
    teacherId: string,
    records: UpsertAttendanceInput[],
  ): Promise<AttendanceSheet> {
    const lesson = await this.lessons.findById(lessonId, teacherId);
    if (!lesson) {
      throw new NotFoundError('Lesson not found');
    }

    const studentIds = records.map((record) => record.studentId);
    const uniqueStudentIds = new Set(studentIds);
    if (uniqueStudentIds.size !== studentIds.length) {
      throw new ValidationError('Duplicate studentId in attendance payload');
    }

    const allBelongToClass = await this.enrollments.areAllStudentsActiveInClass(lesson.classId, studentIds);
    if (!allBelongToClass) {
      throw new ValidationError('Some students do not have an active enrollment in this class');
    }

    await this.attendances.upsertMany(lessonId, teacherId, records);

    return this.getAttendanceSheetUseCase.execute(lessonId, teacherId);
  }
}
