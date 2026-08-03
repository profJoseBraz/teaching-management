export const ENROLLMENT_STATUSES = ['ACTIVE', 'WITHDRAWN'] as const;
export type EnrollmentStatus = (typeof ENROLLMENT_STATUSES)[number];

export type Enrollment = {
  id: string;
  teacherId: string;
  classId: string;
  studentId: string;
  status: EnrollmentStatus;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

/** Matrícula enriquecida com dados do aluno, usada em listagens por turma. */
export type EnrollmentWithStudent = Enrollment & {
  student: {
    id: string;
    name: string;
    registryCode: string | null;
    email: string | null;
  };
};
