import type { Enrollment, EnrollmentWithStudent } from '../../domain/enrollment';

export type CreateEnrollmentInput = {
  teacherId: string;
  classId: string;
  studentId: string;
};

export interface EnrollmentRepository {
  findByClassAndStudent(
    teacherId: string,
    classId: string,
    studentId: string,
  ): Promise<Enrollment | null>;
  create(input: CreateEnrollmentInput): Promise<Enrollment>;
  reactivate(teacherId: string, id: string): Promise<Enrollment>;
  withdraw(teacherId: string, classId: string, studentId: string): Promise<void>;
  listByClass(teacherId: string, classId: string): Promise<EnrollmentWithStudent[]>;
}
