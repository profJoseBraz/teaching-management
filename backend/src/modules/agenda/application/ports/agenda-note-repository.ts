import type { AgendaNote } from '../../domain/agenda-note';

export type CreateAgendaNoteInput = {
  teacherId: string;
  date: Date;
  content: string;
  completed?: boolean;
};

export type UpdateAgendaNoteInput = Partial<{
  date: Date;
  content: string;
  completed: boolean;
}>;

export type ListAgendaNotesFilters = {
  from?: Date;
  to?: Date;
  search?: string;
  /** `undefined` = todas; `true`/`false` filtra por status. */
  completed?: boolean;
};

export interface AgendaNoteRepository {
  create(input: CreateAgendaNoteInput): Promise<AgendaNote>;
  findById(teacherId: string, id: string): Promise<AgendaNote | null>;
  list(teacherId: string, filters?: ListAgendaNotesFilters): Promise<AgendaNote[]>;
  update(teacherId: string, id: string, input: UpdateAgendaNoteInput): Promise<AgendaNote>;
  delete(teacherId: string, id: string): Promise<void>;
}
