import type { AgendaNote } from '../../domain/agenda-note';
import type { AgendaNoteRepository, CreateAgendaNoteInput } from '../ports/agenda-note-repository';

export class CreateAgendaNoteUseCase {
  constructor(private readonly notes: AgendaNoteRepository) {}

  async execute(input: CreateAgendaNoteInput): Promise<AgendaNote> {
    return this.notes.create({
      ...input,
      completed: input.completed ?? false,
    });
  }
}
