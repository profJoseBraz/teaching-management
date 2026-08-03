import type { ClassDisciplineGateway } from '../../../../shared/application/ports/class-discipline-gateway';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import { ValidationError } from '../../../../shared/domain/errors';
import type { Content } from '../../domain/content';
import type { ContentRepository } from '../ports/content-repository';

export type CreateContentInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
  title: string;
  description?: string | null;
};

export class CreateContentUseCase {
  constructor(
    private readonly contents: ContentRepository,
    private readonly classOwnership: ClassOwnershipChecker,
    private readonly classDisciplines: ClassDisciplineGateway,
  ) {}

  async execute(input: CreateContentInput): Promise<Content> {
    const owned = await this.classOwnership.isOwnedByTeacher(input.classId, input.teacherId);
    if (!owned) {
      throw new ValidationError('Class not found for this teacher');
    }

    const linked = await this.classDisciplines.isLinked(input.teacherId, input.classId, input.disciplineId);
    if (!linked) {
      throw new ValidationError('Discipline is not linked to this class');
    }

    return this.contents.create({
      teacherId: input.teacherId,
      classId: input.classId,
      disciplineId: input.disciplineId,
      title: input.title,
      description: input.description ?? null,
    });
  }
}
