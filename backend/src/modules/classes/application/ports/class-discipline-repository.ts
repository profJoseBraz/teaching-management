import type { ClassDiscipline, ClassDisciplineDetail } from '../../domain/class-discipline';

export type CreateClassDisciplineInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
};

export interface ClassDisciplineRepository {
  /** Retorna o vínculo mesmo se soft-deletado, para permitir reativação. */
  findLink(teacherId: string, classId: string, disciplineId: string): Promise<ClassDiscipline | null>;
  create(input: CreateClassDisciplineInput): Promise<ClassDiscipline>;
  reactivate(teacherId: string, id: string): Promise<ClassDiscipline>;
  softDeleteLink(teacherId: string, classId: string, disciplineId: string): Promise<void>;
  listByClass(teacherId: string, classId: string): Promise<ClassDisciplineDetail[]>;
  /** Busca em lote os vínculos ativos de várias turmas — evita N+1 em `ListClasses`. */
  listActiveByClasses(teacherId: string, classIds: string[]): Promise<Map<string, ClassDisciplineDetail[]>>;
}
