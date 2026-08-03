import type { Lesson } from '../../domain/lesson';

export type CreateLessonInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
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
}>;

export interface LessonRepository {
  create(input: CreateLessonInput): Promise<Lesson>;
  update(id: string, teacherId: string, input: UpdateLessonInput): Promise<Lesson>;
  findById(id: string, teacherId: string): Promise<Lesson | null>;
  listByClass(classId: string, teacherId: string, disciplineId?: string): Promise<Lesson[]>;
  softDelete(id: string, teacherId: string): Promise<void>;
}
