import type { EnrollmentGateway } from '../../../../shared/application/ports/enrollment-gateway';
import type { LessonGateway } from '../../../../shared/application/ports/lesson-gateway';
import { NotFoundError } from '../../../../shared/domain/errors';
import type { AttendanceSheet } from '../../domain/attendance';
import type { AttendanceRepository } from '../ports/attendance-repository';

export class GetAttendanceSheetUseCase {
  constructor(
    private readonly attendances: AttendanceRepository,
    private readonly lessons: LessonGateway,
    private readonly enrollments: EnrollmentGateway,
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

    const recordByStudentId = new Map(records.map((record) => [record.studentId, record]));

    return {
      lessonId,
      classId: lesson.classId,
      attendanceCompleted: lesson.attendanceCompleted,
      students: activeStudents.map((student) => {
        const record = recordByStudentId.get(student.studentId);
        return {
          studentId: student.studentId,
          studentName: student.studentName,
          status: record?.status ?? null,
          observations: record?.observations ?? null,
        };
      }),
    };
  }
}
