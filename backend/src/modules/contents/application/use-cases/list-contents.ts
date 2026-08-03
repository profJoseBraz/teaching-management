import { ValidationError } from '../../../../shared/domain/errors';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import type { Content, ContentStatus } from '../../domain/content';
import type { ContentRepository } from '../ports/content-repository';

export class ListContentsUseCase {
  constructor(
    private readonly contents: ContentRepository,
    private readonly classOwnership: ClassOwnershipChecker,
  ) {}

  async execute(
    classId: string,
    teacherId: string,
    status?: ContentStatus,
    disciplineId?: string,
  ): Promise<Content[]> {
    const owned = await this.classOwnership.isOwnedByTeacher(classId, teacherId);
    if (!owned) {
      throw new ValidationError('Class not found for this teacher');
    }

    return this.contents.listByClass(classId, teacherId, status, disciplineId);
  }
}
