import { NotFoundError } from '../../../../shared/domain/errors';
import type { AgendaNoteRepository } from '../ports/agenda-note-repository';

export class DeleteAgendaNoteUseCase {
  constructor(private readonly notes: AgendaNoteRepository) {}

  async execute(teacherId: string, id: string): Promise<void> {
    const existing = await this.notes.findById(teacherId, id);
    if (!existing) {
      throw new NotFoundError('Agenda note not found');
    }
    await this.notes.delete(teacherId, id);
  }
}
