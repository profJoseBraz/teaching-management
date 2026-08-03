import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Content } from '../../domain/content';
import type { ContentRepository } from '../ports/content-repository';

export class CompleteContentUseCase {
  constructor(private readonly contents: ContentRepository) {}

  async execute(id: string, teacherId: string): Promise<Content> {
    const existing = await this.contents.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Content not found');
    }

    if (existing.status === 'COMPLETED') {
      throw new ValidationError('Content is already completed');
    }

    return this.contents.setStatus(id, teacherId, 'COMPLETED', new Date());
  }
}
