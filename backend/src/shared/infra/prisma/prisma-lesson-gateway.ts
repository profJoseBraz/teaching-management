import type { LessonGateway, LessonSummary } from '../../application/ports/lesson-gateway';
import { prisma } from './prisma-client';

export class PrismaLessonGateway implements LessonGateway {
  async findById(lessonId: string, teacherId: string): Promise<LessonSummary | null> {
    const row = await prisma.lesson.findFirst({
      where: { id: lessonId, teacherId, deletedAt: null },
      select: { id: true, teacherId: true, classId: true, disciplineId: true, attendanceCompleted: true },
    });
    return row;
  }

  async markAttendanceCompleted(lessonId: string): Promise<void> {
    await prisma.lesson.update({
      where: { id: lessonId },
      data: { attendanceCompleted: true },
    });
  }
}
