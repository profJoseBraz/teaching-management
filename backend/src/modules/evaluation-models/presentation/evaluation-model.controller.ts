import type { Request, Response } from 'express';
import type { CreateEvaluationModelUseCase } from '../application/use-cases/create-evaluation-model';
import type { CreateEvaluationModelItemUseCase } from '../application/use-cases/create-evaluation-model-item';
import type { DeactivateEvaluationModelUseCase } from '../application/use-cases/deactivate-evaluation-model';
import type { GetEvaluationModelUseCase } from '../application/use-cases/get-evaluation-model';
import type { ListEvaluationModelsUseCase } from '../application/use-cases/list-evaluation-models';
import type { ReorderEvaluationModelItemsUseCase } from '../application/use-cases/reorder-evaluation-model-items';
import type { SoftDeleteEvaluationModelUseCase } from '../application/use-cases/soft-delete-evaluation-model';
import type { SoftDeleteEvaluationModelItemUseCase } from '../application/use-cases/soft-delete-evaluation-model-item';
import type { UpdateEvaluationModelUseCase } from '../application/use-cases/update-evaluation-model';
import type { UpdateEvaluationModelItemUseCase } from '../application/use-cases/update-evaluation-model-item';

export class EvaluationModelController {
  constructor(
    private readonly createEvaluationModelUseCase: CreateEvaluationModelUseCase,
    private readonly updateEvaluationModelUseCase: UpdateEvaluationModelUseCase,
    private readonly listEvaluationModelsUseCase: ListEvaluationModelsUseCase,
    private readonly getEvaluationModelUseCase: GetEvaluationModelUseCase,
    private readonly softDeleteEvaluationModelUseCase: SoftDeleteEvaluationModelUseCase,
    private readonly deactivateEvaluationModelUseCase: DeactivateEvaluationModelUseCase,
    private readonly createEvaluationModelItemUseCase: CreateEvaluationModelItemUseCase,
    private readonly updateEvaluationModelItemUseCase: UpdateEvaluationModelItemUseCase,
    private readonly softDeleteEvaluationModelItemUseCase: SoftDeleteEvaluationModelItemUseCase,
    private readonly reorderEvaluationModelItemsUseCase: ReorderEvaluationModelItemsUseCase,
  ) {}

  list = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const includeInactive = Boolean(
      (req.query as { includeInactive?: boolean }).includeInactive,
    );
    const result = await this.listEvaluationModelsUseCase.execute(teacherId, {
      includeInactive,
    });
    res.status(200).json({ data: result });
  };

  get = async (req: Request, res: Response): Promise<void> => {
    const result = await this.getEvaluationModelUseCase.execute(
      req.auth!.teacherId,
      req.params.id as string,
    );
    res.status(200).json({ data: result });
  };

  create = async (req: Request, res: Response): Promise<void> => {
    const result = await this.createEvaluationModelUseCase.execute({
      teacherId: req.auth!.teacherId,
      name: req.body.name,
      description: req.body.description,
      sortOrder: req.body.sortOrder,
      items: req.body.items,
    });
    res.status(201).json({ data: result });
  };

  update = async (req: Request, res: Response): Promise<void> => {
    const result = await this.updateEvaluationModelUseCase.execute(
      req.auth!.teacherId,
      req.params.id as string,
      req.body,
    );
    res.status(200).json({ data: result });
  };

  softDelete = async (req: Request, res: Response): Promise<void> => {
    await this.softDeleteEvaluationModelUseCase.execute(
      req.auth!.teacherId,
      req.params.id as string,
    );
    res.status(204).send();
  };

  deactivate = async (req: Request, res: Response): Promise<void> => {
    const result = await this.deactivateEvaluationModelUseCase.execute(
      req.auth!.teacherId,
      req.params.id as string,
    );
    res.status(200).json({ data: result });
  };

  createItem = async (req: Request, res: Response): Promise<void> => {
    const result = await this.createEvaluationModelItemUseCase.execute({
      teacherId: req.auth!.teacherId,
      evaluationModelId: req.params.id as string,
      name: req.body.name,
      maxScore: req.body.maxScore,
      sortOrder: req.body.sortOrder,
      isRecovery: req.body.isRecovery,
      recoversItemId: req.body.recoversItemId,
    });
    res.status(201).json({ data: result });
  };

  updateItem = async (req: Request, res: Response): Promise<void> => {
    const result = await this.updateEvaluationModelItemUseCase.execute(
      req.auth!.teacherId,
      req.params.id as string,
      req.params.itemId as string,
      req.body,
    );
    res.status(200).json({ data: result });
  };

  softDeleteItem = async (req: Request, res: Response): Promise<void> => {
    await this.softDeleteEvaluationModelItemUseCase.execute(
      req.auth!.teacherId,
      req.params.id as string,
      req.params.itemId as string,
    );
    res.status(204).send();
  };

  reorderItems = async (req: Request, res: Response): Promise<void> => {
    const result = await this.reorderEvaluationModelItemsUseCase.execute(
      req.auth!.teacherId,
      req.params.id as string,
      req.body.itemIds,
    );
    res.status(200).json({ data: result });
  };
}
