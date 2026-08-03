import type { Request, Response } from 'express';
import type { ContentStatus } from '../domain/content';
import type { CompleteContentUseCase } from '../application/use-cases/complete-content';
import type { CreateContentUseCase } from '../application/use-cases/create-content';
import type { LinkContentToLessonUseCase } from '../application/use-cases/link-content-to-lesson';
import type { ListContentsUseCase } from '../application/use-cases/list-contents';
import type { ReopenContentUseCase } from '../application/use-cases/reopen-content';
import type { UnlinkContentFromLessonUseCase } from '../application/use-cases/unlink-content-from-lesson';
import type { UpdateContentUseCase } from '../application/use-cases/update-content';

export class ContentController {
  constructor(
    private readonly createContentUseCase: CreateContentUseCase,
    private readonly updateContentUseCase: UpdateContentUseCase,
    private readonly listContentsUseCase: ListContentsUseCase,
    private readonly completeContentUseCase: CompleteContentUseCase,
    private readonly reopenContentUseCase: ReopenContentUseCase,
    private readonly linkContentToLessonUseCase: LinkContentToLessonUseCase,
    private readonly unlinkContentFromLessonUseCase: UnlinkContentFromLessonUseCase,
  ) {}

  list = async (req: Request, res: Response): Promise<void> => {
    const { classId } = req.params as { classId: string };
    const { status, disciplineId } = req.query as { status?: ContentStatus; disciplineId?: string };
    const contents = await this.listContentsUseCase.execute(classId, req.auth!.teacherId, status, disciplineId);
    res.status(200).json({ data: contents });
  };

  create = async (req: Request, res: Response): Promise<void> => {
    const { classId } = req.params as { classId: string };
    const content = await this.createContentUseCase.execute({
      ...req.body,
      classId,
      teacherId: req.auth!.teacherId,
    });
    res.status(201).json({ data: content });
  };

  update = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const content = await this.updateContentUseCase.execute(id, req.auth!.teacherId, req.body);
    res.status(200).json({ data: content });
  };

  complete = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const content = await this.completeContentUseCase.execute(id, req.auth!.teacherId);
    res.status(200).json({ data: content });
  };

  reopen = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const content = await this.reopenContentUseCase.execute(id, req.auth!.teacherId);
    res.status(200).json({ data: content });
  };

  linkToLesson = async (req: Request, res: Response): Promise<void> => {
    const { lessonId } = req.params as { lessonId: string };
    const { contentId } = req.body as { contentId: string };
    await this.linkContentToLessonUseCase.execute(lessonId, contentId, req.auth!.teacherId);
    res.status(201).json({ data: { lessonId, contentId } });
  };

  unlinkFromLesson = async (req: Request, res: Response): Promise<void> => {
    const { lessonId, contentId } = req.params as { lessonId: string; contentId: string };
    await this.unlinkContentFromLessonUseCase.execute(lessonId, contentId, req.auth!.teacherId);
    res.status(204).send();
  };
}
