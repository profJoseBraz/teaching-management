import type { Submission as PrismaSubmission, SubmissionStatus as PrismaSubmissionStatus } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { Submission, SubmissionStatus } from '../domain/submission';
import type { SubmissionRepository } from '../application/ports/submission-repository';

function mapSubmission(row: PrismaSubmission): Submission {
  return {
    id: row.id,
    teacherId: row.teacherId,
    activityId: row.activityId,
    studentId: row.studentId,
    groupId: row.groupId,
    status: row.status as SubmissionStatus,
    score: row.score !== null ? Number(row.score) : null,
    observations: row.observations,
    submittedAt: row.submittedAt,
    gradedAt: row.gradedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaSubmissionRepository implements SubmissionRepository {
  async createManyPending(activityId: string, teacherId: string, studentIds: string[]): Promise<void> {
    await prisma.submission.createMany({
      data: studentIds.map((studentId) => ({
        teacherId,
        activityId,
        studentId,
        status: 'PENDING' as PrismaSubmissionStatus,
      })),
      skipDuplicates: true,
    });
  }

  async listByActivity(activityId: string, teacherId: string): Promise<Submission[]> {
    const rows = await prisma.submission.findMany({
      where: { activityId, teacherId, deletedAt: null },
      orderBy: { student: { name: 'asc' } },
    });
    return rows.map(mapSubmission);
  }

  async findById(id: string, teacherId: string): Promise<Submission | null> {
    const row = await prisma.submission.findFirst({
      where: { id, teacherId, deletedAt: null },
    });
    return row ? mapSubmission(row) : null;
  }

  async findByIds(ids: string[], teacherId: string): Promise<Submission[]> {
    if (ids.length === 0) {
      return [];
    }
    const rows = await prisma.submission.findMany({
      where: { id: { in: ids }, teacherId, deletedAt: null },
    });
    return rows.map(mapSubmission);
  }

  async updateStatus(
    id: string,
    teacherId: string,
    status: SubmissionStatus,
    submittedAt?: Date | null,
  ): Promise<Submission> {
    const row = await prisma.submission.update({
      where: { id, teacherId, deletedAt: null },
      data: {
        status: status as PrismaSubmissionStatus,
        ...(submittedAt !== undefined ? { submittedAt } : {}),
      },
    });
    return mapSubmission(row);
  }

  async grade(
    id: string,
    teacherId: string,
    score: number,
    observations?: string | null,
  ): Promise<Submission> {
    const row = await prisma.submission.update({
      where: { id, teacherId, deletedAt: null },
      data: {
        status: 'GRADED' as PrismaSubmissionStatus,
        score,
        gradedAt: new Date(),
        ...(observations !== undefined ? { observations } : {}),
      },
    });
    return mapSubmission(row);
  }

  async gradeMany(
    ids: string[],
    teacherId: string,
    score: number,
    observations?: string | null,
  ): Promise<Submission[]> {
    if (ids.length === 0) {
      return [];
    }

    const now = new Date();
    await prisma.submission.updateMany({
      where: { id: { in: ids }, teacherId, deletedAt: null },
      data: {
        status: 'GRADED' as PrismaSubmissionStatus,
        score,
        gradedAt: now,
        observations: observations ?? null,
      },
    });

    const rows = await prisma.submission.findMany({
      where: { id: { in: ids }, teacherId, deletedAt: null },
      orderBy: { student: { name: 'asc' } },
    });
    return rows.map(mapSubmission);
  }

  async assignGroup(submissionIds: string[], groupId: string): Promise<void> {
    if (submissionIds.length === 0) {
      return;
    }
    await prisma.submission.updateMany({
      where: { id: { in: submissionIds } },
      data: { groupId },
    });
  }

  async gradeByGroup(
    groupId: string,
    teacherId: string,
    score: number,
    observations?: string | null,
  ): Promise<Submission[]> {
    await prisma.submission.updateMany({
      where: { groupId, teacherId, deletedAt: null },
      data: {
        status: 'GRADED' as PrismaSubmissionStatus,
        score,
        gradedAt: new Date(),
        ...(observations !== undefined ? { observations } : {}),
      },
    });

    const rows = await prisma.submission.findMany({
      where: { groupId, teacherId, deletedAt: null },
    });
    return rows.map(mapSubmission);
  }

  async findByActivityAndStudents(
    activityId: string,
    teacherId: string,
    studentIds: string[],
  ): Promise<Submission[]> {
    if (studentIds.length === 0) {
      return [];
    }
    const rows = await prisma.submission.findMany({
      where: { activityId, teacherId, deletedAt: null, studentId: { in: studentIds } },
    });
    return rows.map(mapSubmission);
  }
}
