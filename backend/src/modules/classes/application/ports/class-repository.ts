import type { Class, ClassShift, ClassStatus } from '../../domain/class';

export type CreateClassInput = {
  teacherId: string;
  academicYearId: string;
  courseId: string;
  name: string;
  shift?: ClassShift | null;
};

export type UpdateClassInput = Partial<{
  name: string;
  shift: ClassShift | null;
}>;

export type ListClassesFilters = {
  academicYearId?: string;
  courseId?: string;
  /** Filtra turmas que possuem vínculo ativo com esta disciplina (via `ClassDiscipline`). */
  disciplineId?: string;
  status?: ClassStatus;
};

export interface ClassRepository {
  create(input: CreateClassInput): Promise<Class>;
  findById(teacherId: string, id: string): Promise<Class | null>;
  findByComposition(
    teacherId: string,
    academicYearId: string,
    courseId: string,
    name: string,
  ): Promise<Class | null>;
  list(teacherId: string, filters?: ListClassesFilters): Promise<Class[]>;
  update(teacherId: string, id: string, input: UpdateClassInput): Promise<Class>;
  archive(teacherId: string, id: string): Promise<Class>;
}
