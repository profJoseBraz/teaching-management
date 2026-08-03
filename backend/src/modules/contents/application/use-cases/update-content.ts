import { NotFoundError } from '../../../../shared/domain/errors';
import type { Content } from '../../domain/content';
import type { ContentRepository, UpdateContentInput } from '../ports/content-repository';

export class UpdateContentUseCase {
  constructor(private readonly contents: ContentRepository) {}

  async execute(id: string, teacherId: string, patch: UpdateContentInput): Promise<Content> {
    const existing = await this.contents.findById(id, teacherId);
    if (!existing) {
      throw new NotFoundError('Content not found');
    }

    return this.contents.update(id, teacherId, patch);
  }
}
