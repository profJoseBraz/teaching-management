import type { Lesson } from '../../domain/lesson';

export type CreateLessonInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
  assessmentPeriodId: string;
  date: Date;
  startTime: string;
  endTime: string;
  observations?: string | null;
};

export type UpdateLessonInput = Partial<{
  date: Date;
  startTime: string;
  endTime: string;
  observations: string | null;
  assessmentPeriodId: string;
}>;

export type ListLessonsFilters = {
  disciplineId?: string;
  assessmentPeriodId?: string;
};

export interface LessonRepository {
  create(input: CreateLessonInput): Promise<Lesson>;
  update(id: string, teacherId: string, input: UpdateLessonInput): Promise<Lesson>;
  findById(id: string, teacherId: string): Promise<Lesson | null>;
  listByClass(classId: string, teacherId: string, filters?: ListLessonsFilters): Promise<Lesson[]>;
  softDelete(id: string, teacherId: string): Promise<void>;
}
