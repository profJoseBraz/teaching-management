import { NotFoundError } from '../../../../shared/domain/errors';
import type { AgendaNote } from '../../domain/agenda-note';
import type { AgendaNoteRepository } from '../ports/agenda-note-repository';

export class GetAgendaNoteUseCase {
  constructor(private readonly notes: AgendaNoteRepository) {}

  async execute(teacherId: string, id: string): Promise<AgendaNote> {
    const note = await this.notes.findById(teacherId, id);
    if (!note) {
      throw new NotFoundError('Agenda note not found');
    }
    return note;
  }
}
