import type { Request, Response } from 'express';
import type { CreateLessonUseCase } from '../application/use-cases/create-lesson';
import type { GetLessonUseCase } from '../application/use-cases/get-lesson';
import type { ListLessonsUseCase } from '../application/use-cases/list-lessons';
import type { SoftDeleteLessonUseCase } from '../application/use-cases/soft-delete-lesson';
import type { UpdateLessonUseCase } from '../application/use-cases/update-lesson';

export class LessonController {
  constructor(
    private readonly createLessonUseCase: CreateLessonUseCase,
    private readonly updateLessonUseCase: UpdateLessonUseCase,
    private readonly listLessonsUseCase: ListLessonsUseCase,
    private readonly getLessonUseCase: GetLessonUseCase,
    private readonly softDeleteLessonUseCase: SoftDeleteLessonUseCase,
  ) {}

  list = async (req: Request, res: Response): Promise<void> => {
    const { classId } = req.params as { classId: string };
    const { disciplineId } = req.query as { disciplineId?: string };
    const lessons = await this.listLessonsUseCase.execute(classId, req.auth!.teacherId, disciplineId);
    res.status(200).json({ data: lessons });
  };

  create = async (req: Request, res: Response): Promise<void> => {
    const { classId } = req.params as { classId: string };
    const lesson = await this.createLessonUseCase.execute({
      ...req.body,
      classId,
      teacherId: req.auth!.teacherId,
    });
    res.status(201).json({ data: lesson });
  };

  get = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const lesson = await this.getLessonUseCase.execute(id, req.auth!.teacherId);
    res.status(200).json({ data: lesson });
  };

  update = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const lesson = await this.updateLessonUseCase.execute(id, req.auth!.teacherId, req.body);
    res.status(200).json({ data: lesson });
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    await this.softDeleteLessonUseCase.execute(id, req.auth!.teacherId);
    res.status(204).send();
  };
}
