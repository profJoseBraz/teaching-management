import type { Discipline } from '../../domain/discipline';

export type CreateDisciplineInput = {
  teacherId: string;
  name: string;
  description?: string | null;
};

export type UpdateDisciplineInput = Partial<{
  name: string;
  description: string | null;
}>;

export interface DisciplineRepository {
  create(input: CreateDisciplineInput): Promise<Discipline>;
  findById(teacherId: string, id: string): Promise<Discipline | null>;
  findByName(teacherId: string, name: string): Promise<Discipline | null>;
  list(teacherId: string): Promise<Discipline[]>;
  update(teacherId: string, id: string, input: UpdateDisciplineInput): Promise<Discipline>;
  softDelete(teacherId: string, id: string): Promise<void>;
}
