import type {
  ActiveEnrollmentStudent,
  EnrollmentGateway,
} from '../../application/ports/enrollment-gateway';
import { prisma } from './prisma-client';

export class PrismaEnrollmentGateway implements EnrollmentGateway {
  async listActiveStudents(classId: string): Promise<ActiveEnrollmentStudent[]> {
    const rows = await prisma.enrollment.findMany({
      where: { classId, status: 'ACTIVE', deletedAt: null, student: { deletedAt: null } },
      select: { student: { select: { id: true, name: true } } },
      orderBy: { student: { name: 'asc' } },
    });

    return rows.map((row) => ({ studentId: row.student.id, studentName: row.student.name }));
  }

  async areAllStudentsActiveInClass(classId: string, studentIds: string[]): Promise<boolean> {
    if (studentIds.length === 0) {
      return true;
    }

    const uniqueIds = Array.from(new Set(studentIds));
    const count = await prisma.enrollment.count({
      where: {
        classId,
        status: 'ACTIVE',
        deletedAt: null,
        studentId: { in: uniqueIds },
        student: { deletedAt: null },
      },
    });

    return count === uniqueIds.length;
  }
}
