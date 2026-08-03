import type { Student } from '../../domain/student';

export type CreateStudentInput = {
  teacherId: string;
  name: string;
  registryCode?: string | null;
  email?: string | null;
  phone?: string | null;
  notes?: string | null;
};

export type UpdateStudentInput = Partial<{
  name: string;
  registryCode: string | null;
  email: string | null;
  phone: string | null;
  notes: string | null;
}>;

export type ListStudentsFilters = {
  search?: string;
};

export interface StudentRepository {
  create(input: CreateStudentInput): Promise<Student>;
  findById(teacherId: string, id: string): Promise<Student | null>;
  list(teacherId: string, filters?: ListStudentsFilters): Promise<Student[]>;
  update(teacherId: string, id: string, input: UpdateStudentInput): Promise<Student>;
  softDelete(teacherId: string, id: string): Promise<void>;
}
