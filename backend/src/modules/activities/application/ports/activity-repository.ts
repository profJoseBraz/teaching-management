import type { Activity, ActivityCategory, ActivityGradeMode, ActivityMode } from '../../domain/activity';

export type CreateActivityInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
  originLessonId: string;
  assessmentPeriodId?: string | null;
  title: string;
  description?: string | null;
  category: ActivityCategory;
  mode: ActivityMode;
  gradeMode: ActivityGradeMode;
  maxScore: number;
  dueDate: Date;
};

export type UpdateActivityInput = Partial<{
  title: string;
  description: string | null;
  category: ActivityCategory;
  mode: ActivityMode;
  gradeMode: ActivityGradeMode;
  maxScore: number;
  dueDate: Date;
  assessmentPeriodId: string | null;
}>;

export interface ActivityRepository {
  create(input: CreateActivityInput): Promise<Activity>;
  update(id: string, teacherId: string, input: UpdateActivityInput): Promise<Activity>;
  findById(id: string, teacherId: string): Promise<Activity | null>;
  listByClass(classId: string, teacherId: string, disciplineId?: string): Promise<Activity[]>;
}
