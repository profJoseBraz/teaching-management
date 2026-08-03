export type ContentStatus = 'IN_PROGRESS' | 'COMPLETED';

export type Content = {
  id: string;
  teacherId: string;
  classId: string;
  disciplineId: string;
  title: string;
  description: string | null;
  status: ContentStatus;
  startedAt: Date;
  completedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
