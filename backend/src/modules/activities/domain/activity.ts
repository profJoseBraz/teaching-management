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
  /** Disciplinas vinculadas à atividade (N:N via ActivityDiscipline). Mín. 1. */
  disciplineIds: string[];
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
  /** Professor confirma que a avaliação da atividade foi encerrada. */
  evaluated: boolean;
  evaluatedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
