import type { LessonGateway } from '../../../../shared/application/ports/lesson-gateway';
import { NotFoundError } from '../../../../shared/domain/errors';
import type { ContentRepository } from '../ports/content-repository';
import type { LessonContentRepository } from '../ports/lesson-content-repository';

export class UnlinkContentFromLessonUseCase {
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

    const linked = await this.lessonContents.exists(lessonId, contentId);
    if (!linked) {
      throw new NotFoundError('Content is not linked to this lesson');
    }

    await this.lessonContents.unlink(lessonId, contentId);
  }
}
