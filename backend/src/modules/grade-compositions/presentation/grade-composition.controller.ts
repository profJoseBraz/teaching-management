import type { Request, Response } from 'express';
import type { CalculateGradeCompositionUseCase } from '../application/use-cases/calculate-grade-composition';
import type { GetGradeCompositionByContextUseCase } from '../application/use-cases/get-grade-composition-by-context';
import type { SoftDeleteGradeCompositionUseCase } from '../application/use-cases/soft-delete-grade-composition';
import type { UpsertGradeCompositionUseCase } from '../application/use-cases/upsert-grade-composition';

export class GradeCompositionController {
  constructor(
    private readonly getByContextUseCase: GetGradeCompositionByContextUseCase,
    private readonly upsertUseCase: UpsertGradeCompositionUseCase,
    private readonly softDeleteUseCase: SoftDeleteGradeCompositionUseCase,
    private readonly calculateUseCase: CalculateGradeCompositionUseCase,
  ) {}

  getByContext = async (req: Request, res: Response): Promise<void> => {
    const result = await this.getByContextUseCase.execute({
      teacherId: req.auth!.teacherId,
      classId: req.query.classId as string,
      disciplineId: req.query.disciplineId as string,
      assessmentPeriodId: req.query.assessmentPeriodId as string,
    });
    res.status(200).json({ data: result });
  };

  upsert = async (req: Request, res: Response): Promise<void> => {
    const result = await this.upsertUseCase.execute({
      teacherId: req.auth!.teacherId,
      classId: req.body.classId,
      disciplineId: req.body.disciplineId,
      assessmentPeriodId: req.body.assessmentPeriodId,
      evaluationModelId: req.body.evaluationModelId,
      groups: req.body.groups,
    });
    res.status(200).json({ data: result });
  };

  softDelete = async (req: Request, res: Response): Promise<void> => {
    await this.softDeleteUseCase.execute(req.auth!.teacherId, req.params.id as string);
    res.status(204).send();
  };

  calculate = async (req: Request, res: Response): Promise<void> => {
    const result = await this.calculateUseCase.execute(
      req.auth!.teacherId,
      req.params.id as string,
    );
    res.status(200).json({ data: result });
  };
}
