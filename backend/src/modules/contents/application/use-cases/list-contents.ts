import { ValidationError } from '../../../../shared/domain/errors';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import type { Content } from '../../domain/content';
import type { ContentRepository, ListContentsFilters } from '../ports/content-repository';

export class ListContentsUseCase {
  constructor(
    private readonly contents: ContentRepository,
    private readonly classOwnership: ClassOwnershipChecker,
  ) {}

  async execute(
    classId: string,
    teacherId: string,
    filters: ListContentsFilters = {},
  ): Promise<Content[]> {
    const owned = await this.classOwnership.isOwnedByTeacher(classId, teacherId);
    if (!owned) {
      throw new ValidationError('Class not found for this teacher');
    }

    return this.contents.listByClass(classId, teacherId, filters);
  }
}
