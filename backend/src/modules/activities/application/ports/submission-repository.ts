import type { Submission, SubmissionStatus } from '../../domain/submission';

export interface SubmissionRepository {
  createManyPending(activityId: string, teacherId: string, studentIds: string[]): Promise<void>;
  listByActivity(activityId: string, teacherId: string): Promise<Submission[]>;
  findById(id: string, teacherId: string): Promise<Submission | null>;
  findByIds(ids: string[], teacherId: string): Promise<Submission[]>;
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
  /** Atribui a mesma nota a várias entregas; retorna as linhas atualizadas (nome A→Z). */
  gradeMany(
    ids: string[],
    teacherId: string,
    score: number,
    observations?: string | null,
  ): Promise<Submission[]>;
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
