import type { Activity, ActivityCategory, ActivityGradeMode, ActivityMode } from '../../domain/activity';

export type CreateActivityInput = {
  teacherId: string;
  classId: string;
  disciplineIds: string[];
  originLessonId?: string | null;
  assessmentPeriodId: string;
  title: string;
  description?: string | null;
  tag?: string | null;
  category: ActivityCategory;
  mode: ActivityMode;
  gradeMode: ActivityGradeMode;
  maxScore: number;
  dueDate: Date;
};

export type UpdateActivityInput = Partial<{
  title: string;
  description: string | null;
  tag: string | null;
  category: ActivityCategory;
  mode: ActivityMode;
  gradeMode: ActivityGradeMode;
  maxScore: number;
  dueDate: Date;
  assessmentPeriodId: string | null;
  disciplineIds: string[];
  evaluated: boolean;
  evaluatedAt: Date | null;
}>;

export type ListActivitiesFilters = {
  disciplineId?: string;
  tag?: string;
  assessmentPeriodId?: string;
};

export interface ActivityRepository {
  create(input: CreateActivityInput): Promise<Activity>;
  update(id: string, teacherId: string, input: UpdateActivityInput): Promise<Activity>;
  findById(id: string, teacherId: string): Promise<Activity | null>;
  listByClass(classId: string, teacherId: string, filters?: ListActivitiesFilters): Promise<Activity[]>;
  softDelete(id: string, teacherId: string): Promise<void>;
}
