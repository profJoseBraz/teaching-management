import type { CourseDiscipline, CourseDisciplineDetail } from '../../domain/course-discipline';

export type CreateCourseDisciplineInput = {
  teacherId: string;
  courseId: string;
  disciplineId: string;
};

export interface CourseDisciplineRepository {
  /** Retorna o vínculo mesmo se soft-deletado, para permitir reativação. */
  findLink(teacherId: string, courseId: string, disciplineId: string): Promise<CourseDiscipline | null>;
  create(input: CreateCourseDisciplineInput): Promise<CourseDiscipline>;
  reactivate(teacherId: string, id: string): Promise<CourseDiscipline>;
  softDeleteLink(teacherId: string, courseId: string, disciplineId: string): Promise<void>;
  listByCourse(teacherId: string, courseId: string): Promise<CourseDisciplineDetail[]>;
}
