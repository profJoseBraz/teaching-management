import type { LessonGateway } from '../../../../shared/application/ports/lesson-gateway';
import { ConflictError, NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { ContentRepository } from '../ports/content-repository';
import type { LessonContentRepository } from '../ports/lesson-content-repository';

export class LinkContentToLessonUseCase {
  constructor(
    private readonly lessonContents: LessonContentRepository,
    private readonly contents: ContentRepository,
    private readonly lessons: LessonGateway,
  ) {}

  async execute(lessonId: string, contentId: string, teacherId: string): Promise<void> {
    const lesson = await this.lessons.findById(lessonId, teacherId);
    if (!lesson) {
      throw new NotFoundError('Lesson not found');
    }

    const content = await this.contents.findById(contentId, teacherId);
    if (!content) {
      throw new NotFoundError('Content not found');
    }

    if (content.classId !== lesson.classId) {
      throw new ValidationError('Content does not belong to the same class as the lesson');
    }

    const alreadyLinked = await this.lessonContents.exists(lessonId, contentId);
    if (alreadyLinked) {
      throw new ConflictError('Content is already linked to this lesson');
    }

    await this.lessonContents.link(lessonId, contentId);
  }
}
