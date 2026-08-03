import { z } from 'zod';

export const lessonIdParamSchema = z.object({
  lessonId: z.uuid(),
});

const attendanceEntrySchema = z.object({
  studentId: z.uuid(),
  status: z.enum(['PRESENT', 'ABSENT', 'LATE']),
  observations: z.string().trim().max(2000).nullish(),
});

export const saveAttendanceSchema = z.object({
  records: z.array(attendanceEntrySchema).min(1),
});
