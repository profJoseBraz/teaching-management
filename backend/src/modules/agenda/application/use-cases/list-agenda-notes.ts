import type { AgendaNote } from '../../domain/agenda-note';
import type { AgendaNoteRepository, ListAgendaNotesFilters } from '../ports/agenda-note-repository';

export class ListAgendaNotesUseCase {
  constructor(private readonly notes: AgendaNoteRepository) {}

  async execute(teacherId: string, filters?: ListAgendaNotesFilters): Promise<AgendaNote[]> {
    return this.notes.list(teacherId, filters);
  }
}
