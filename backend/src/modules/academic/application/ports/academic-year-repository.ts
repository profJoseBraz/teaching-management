import type { AcademicYear } from '../../domain/academic-year';

export type CreateAcademicYearInput = {
  teacherId: string;
  year: number;
  label?: string | null;
  startsOn?: Date | null;
  endsOn?: Date | null;
};

export type UpdateAcademicYearInput = Partial<{
  label: string | null;
  startsOn: Date | null;
  endsOn: Date | null;
}>;

export interface AcademicYearRepository {
  create(input: CreateAcademicYearInput): Promise<AcademicYear>;
  findById(teacherId: string, id: string): Promise<AcademicYear | null>;
  /** Ignora deletedAt: a constraint única do banco não distingue registros removidos. */
  findByYear(teacherId: string, year: number): Promise<AcademicYear | null>;
  list(teacherId: string): Promise<AcademicYear[]>;
  update(teacherId: string, id: string, input: UpdateAcademicYearInput): Promise<AcademicYear>;
  /** Marca `id` como atual e desmarca os demais anos do mesmo professor, atomicamente. */
  setCurrent(teacherId: string, id: string): Promise<AcademicYear>;
}
