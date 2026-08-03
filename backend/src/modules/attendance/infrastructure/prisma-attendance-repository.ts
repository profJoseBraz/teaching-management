import type { Attendance as PrismaAttendance, AttendanceStatus as PrismaAttendanceStatus } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { AttendanceRecord, AttendanceStatus } from '../domain/attendance';
import type {
  AttendanceRepository,
  UpsertAttendanceInput,
} from '../application/ports/attendance-repository';

function mapAttendance(row: PrismaAttendance): AttendanceRecord {
  return {
    id: row.id,
    teacherId: row.teacherId,
    lessonId: row.lessonId,
    studentId: row.studentId,
    status: row.status as AttendanceStatus,
    observations: row.observations,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

export class PrismaAttendanceRepository implements AttendanceRepository {
  async listByLesson(lessonId: string, teacherId: string): Promise<AttendanceRecord[]> {
    const rows = await prisma.attendance.findMany({
      where: { lessonId, teacherId },
    });
    return rows.map(mapAttendance);
  }

  async upsertMany(
    lessonId: string,
    teacherId: string,
    records: UpsertAttendanceInput[],
  ): Promise<AttendanceRecord[]> {
    const rows = await prisma.$transaction(
      records.map((record) =>
        prisma.attendance.upsert({
          where: { lessonId_studentId: { lessonId, studentId: record.studentId } },
          create: {
            teacherId,
            lessonId,
            studentId: record.studentId,
            status: record.status as PrismaAttendanceStatus,
            observations: record.observations ?? null,
          },
          update: {
            status: record.status as PrismaAttendanceStatus,
            observations: record.observations ?? null,
          },
        }),
      ),
    );

    return rows.map(mapAttendance);
  }
}
