import type { AttendanceRecord, AttendanceStatus } from '../../domain/attendance';

export type UpsertAttendanceInput = {
  studentId: string;
  status: AttendanceStatus;
  observations?: string | null;
};

export interface AttendanceRepository {
  listByLesson(lessonId: string, teacherId: string): Promise<AttendanceRecord[]>;
  upsertMany(
    lessonId: string,
    teacherId: string,
    records: UpsertAttendanceInput[],
  ): Promise<AttendanceRecord[]>;
}
