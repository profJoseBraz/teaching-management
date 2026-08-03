import type { Submission, SubmissionStatus } from '../../domain/submission';

export interface SubmissionRepository {
  createManyPending(activityId: string, teacherId: string, studentIds: string[]): Promise<void>;
  listByActivity(activityId: string, teacherId: string): Promise<Submission[]>;
  findById(id: string, teacherId: string): Promise<Submission | null>;
  updateStatus(
    id: string,
    teacherId: string,
    status: SubmissionStatus,
    submittedAt?: Date | null,
  ): Promise<Submission>;
  grade(
    id: string,
    teacherId: string,
    score: number,
    observations?: string | null,
  ): Promise<Submission>;
  assignGroup(submissionIds: string[], groupId: string): Promise<void>;
  gradeByGroup(
    groupId: string,
    teacherId: string,
    score: number,
    observations?: string | null,
  ): Promise<Submission[]>;
  findByActivityAndStudents(
    activityId: string,
    teacherId: string,
    studentIds: string[],
  ): Promise<Submission[]>;
}
