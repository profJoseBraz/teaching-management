import { NotFoundError } from '../../../../shared/domain/errors';
import type { AgendaNote } from '../../domain/agenda-note';
import type { AgendaNoteRepository, UpdateAgendaNoteInput } from '../ports/agenda-note-repository';

export class UpdateAgendaNoteUseCase {
  constructor(private readonly notes: AgendaNoteRepository) {}

  async execute(teacherId: string, id: string, input: UpdateAgendaNoteInput): Promise<AgendaNote> {
    const existing = await this.notes.findById(teacherId, id);
    if (!existing) {
      throw new NotFoundError('Agenda note not found');
    }
    return this.notes.update(teacherId, id, input);
  }
}
