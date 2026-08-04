export type ActivityCategory =
  | 'EXERCISE'
  | 'ASSIGNMENT'
  | 'PROJECT'
  | 'RESEARCH'
  | 'SEMINAR'
  | 'EXAM'
  | 'OTHER';

export type ActivityMode = 'INDIVIDUAL' | 'GROUP';
export type ActivityGradeMode = 'SHARED' | 'INDIVIDUAL';

export type Activity = {
  id: string;
  teacherId: string;
  classId: string;
  disciplineId: string;
  originLessonId: string | null;
  assessmentPeriodId: string | null;
  title: string;
  description: string | null;
  /** Rótulo livre opcional para agrupar atividades. */
  tag: string | null;
  category: ActivityCategory;
  mode: ActivityMode;
  gradeMode: ActivityGradeMode;
  maxScore: number;
  createdOn: Date;
  dueDate: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
