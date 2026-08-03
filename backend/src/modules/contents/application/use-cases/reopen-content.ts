import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Content } from '../../domain/content';
import type { ContentRepository } from '../ports/content-repository';

export class ReopenContentUseCase {
  constructor(private readonly contents: ContentRepository) {}

  async execute(id: string, teacherId: string): Promise<Content> {
    const existing = await this.contents.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Content not found');
    }

    if (existing.status === 'IN_PROGRESS') {
      throw new ValidationError('Content is already in progress');
    }

    return this.contents.setStatus(id, teacherId, 'IN_PROGRESS', null);
  }
}
