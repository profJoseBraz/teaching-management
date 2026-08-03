export type SubmissionStatus = 'PENDING' | 'SUBMITTED' | 'GRADED';

export type Submission = {
  id: string;
  teacherId: string;
  activityId: string;
  studentId: string;
  groupId: string | null;
  status: SubmissionStatus;
  score: number | null;
  observations: string | null;
  submittedAt: Date | null;
  gradedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
