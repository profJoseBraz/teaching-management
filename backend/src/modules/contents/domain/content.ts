export type ContentStatus = 'IN_PROGRESS' | 'COMPLETED';

export type Content = {
  id: string;
  teacherId: string;
  classId: string;
  disciplineId: string;
  assessmentPeriodId: string | null;
  title: string;
  description: string | null;
  status: ContentStatus;
  startedAt: Date;
  completedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
