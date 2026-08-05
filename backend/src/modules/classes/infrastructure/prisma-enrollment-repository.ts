import type { Enrollment as PrismaEnrollment } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { Enrollment, EnrollmentStatus, EnrollmentWithStudent } from '../domain/enrollment';
import type {
  CreateEnrollmentInput,
  EnrollmentRepository,
} from '../application/ports/enrollment-repository';

function mapEnrollment(row: PrismaEnrollment): Enrollment {
  return {
    id: row.id,
    teacherId: row.teacherId,
    classId: row.classId,
    studentId: row.studentId,
    status: row.status as EnrollmentStatus,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaEnrollmentRepository implements EnrollmentRepository {
  async findByClassAndStudent(
    teacherId: string,
    classId: string,
    studentId: string,
  ): Promise<Enrollment | null> {
    const row = await prisma.enrollment.findFirst({ where: { teacherId, classId, studentId } });
    return row ? mapEnrollment(row) : null;
  }

  async create(input: CreateEnrollmentInput): Promise<Enrollment> {
    const row = await prisma.enrollment.create({
      data: {
        teacherId: input.teacherId,
        classId: input.classId,
        studentId: input.studentId,
      },
    });
    return mapEnrollment(row);
  }

  async reactivate(teacherId: string, id: string): Promise<Enrollment> {
    await prisma.enrollment.updateMany({
      where: { id, teacherId },
      data: { status: 'ACTIVE', deletedAt: null },
    });
    const row = await prisma.enrollment.findFirstOrThrow({ where: { id, teacherId } });
    return mapEnrollment(row);
  }

  async withdraw(teacherId: string, classId: string, studentId: string): Promise<void> {
    await prisma.enrollment.updateMany({
      where: { teacherId, classId, studentId },
      data: { status: 'WITHDRAWN' },
    });
  }

  async listByClass(teacherId: string, classId: string): Promise<EnrollmentWithStudent[]> {
    const rows = await prisma.enrollment.findMany({
      where: { teacherId, classId, status: 'ACTIVE', deletedAt: null },
      include: {
        student: {
          select: { id: true, name: true, registryCode: true, email: true },
        },
      },
      orderBy: { student: { name: 'asc' } },
    });

    return rows.map((row) => ({
      ...mapEnrollment(row),
      student: row.student,
    }));
  }
}
