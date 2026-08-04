import type { Request, Response } from 'express';
import type { CreateActivityGroupsUseCase } from '../application/use-cases/create-activity-groups';
import type { CreateActivityUseCase } from '../application/use-cases/create-activity';
import type { GetActivityUseCase } from '../application/use-cases/get-activity';
import type { ListActivitiesUseCase } from '../application/use-cases/list-activities';
import type { ListSubmissionsUseCase } from '../application/use-cases/list-submissions';
import type { SoftDeleteActivityUseCase } from '../application/use-cases/soft-delete-activity';
import type { UpdateActivityUseCase } from '../application/use-cases/update-activity';

export class ActivityController {
  constructor(
    private readonly createActivityUseCase: CreateActivityUseCase,
    private readonly updateActivityUseCase: UpdateActivityUseCase,
    private readonly softDeleteActivityUseCase: SoftDeleteActivityUseCase,
    private readonly listActivitiesUseCase: ListActivitiesUseCase,
    private readonly getActivityUseCase: GetActivityUseCase,
    private readonly createActivityGroupsUseCase: CreateActivityGroupsUseCase,
    private readonly listSubmissionsUseCase: ListSubmissionsUseCase,
  ) {}

  list = async (req: Request, res: Response): Promise<void> => {
    const { classId } = req.params as { classId: string };
    const { disciplineId, tag } = req.query as { disciplineId?: string; tag?: string };
    const activities = await this.listActivitiesUseCase.execute(classId, req.auth!.teacherId, {
      disciplineId,
      tag,
    });
    res.status(200).json({ data: activities });
  };

  create = async (req: Request, res: Response): Promise<void> => {
    const { classId } = req.params as { classId: string };
    const activity = await this.createActivityUseCase.execute({
      ...req.body,
      classId,
      teacherId: req.auth!.teacherId,
    });
    res.status(201).json({ data: activity });
  };

  get = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const result = await this.getActivityUseCase.execute(id, req.auth!.teacherId);
    res.status(200).json({ data: result });
  };

  update = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const activity = await this.updateActivityUseCase.execute(id, req.auth!.teacherId, req.body);
    res.status(200).json({ data: activity });
  };

  remove = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    await this.softDeleteActivityUseCase.execute(id, req.auth!.teacherId);
    res.status(204).send();
  };

  createGroups = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const { groups } = req.body as { groups: { name: string; studentIds: string[] }[] };
    const createdGroups = await this.createActivityGroupsUseCase.execute(id, req.auth!.teacherId, groups);
    res.status(201).json({ data: createdGroups });
  };

  listSubmissions = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const submissions = await this.listSubmissionsUseCase.execute(id, req.auth!.teacherId);
    res.status(200).json({ data: submissions });
  };
}
