import type { Course } from '../../domain/course';

export type CreateCourseInput = {
  teacherId: string;
  name: string;
  description?: string | null;
};

export type UpdateCourseInput = Partial<{
  name: string;
  description: string | null;
}>;

export interface CourseRepository {
  create(input: CreateCourseInput): Promise<Course>;
  findById(teacherId: string, id: string): Promise<Course | null>;
  findByName(teacherId: string, name: string): Promise<Course | null>;
  list(teacherId: string): Promise<Course[]>;
  update(teacherId: string, id: string, input: UpdateCourseInput): Promise<Course>;
  softDelete(teacherId: string, id: string): Promise<void>;
}
