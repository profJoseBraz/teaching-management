import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { LessonContentRepository } from '../application/ports/lesson-content-repository';

export class PrismaLessonContentRepository implements LessonContentRepository {
  async exists(lessonId: string, contentId: string): Promise<boolean> {
    const found = await prisma.lessonContent.findUnique({
      where: { lessonId_contentId: { lessonId, contentId } },
      select: { id: true },
    });
    return found !== null;
  }

  async link(lessonId: string, contentId: string): Promise<void> {
    await prisma.lessonContent.create({
      data: { lessonId, contentId },
    });
  }

  async unlink(lessonId: string, contentId: string): Promise<void> {
    await prisma.lessonContent.delete({
      where: { lessonId_contentId: { lessonId, contentId } },
    });
  }
}
