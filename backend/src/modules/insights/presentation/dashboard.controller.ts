import type { Request, Response } from 'express';
import type { ParamsDictionary } from 'express-serve-static-core';
import type { GetAttentionItemsUseCase } from '../application/use-cases/get-attention-items';
import type { GetDashboardUseCase } from '../application/use-cases/get-dashboard';

type DashboardQuery = { academicYearId?: string; classId?: string };

/** Adapta HTTP <-> Use Cases do Insights Engine. Nenhuma regra de negócio aqui. */
export class DashboardController {
  constructor(
    private readonly getDashboardUseCase: GetDashboardUseCase,
    private readonly getAttentionItemsUseCase: GetAttentionItemsUseCase,
  ) {}

  getDashboard = async (
    req: Request<ParamsDictionary, unknown, unknown, DashboardQuery>,
    res: Response,
  ): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const { academicYearId, classId } = req.query;
    const result = await this.getDashboardUseCase.execute({ teacherId, academicYearId, classId });
    res.status(200).json({ data: result });
  };

  getAttentionItems = async (
    req: Request<ParamsDictionary, unknown, unknown, DashboardQuery>,
    res: Response,
  ): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const { academicYearId, classId } = req.query;
    const attentionItems = await this.getAttentionItemsUseCase.execute({ teacherId, academicYearId, classId });
    res.status(200).json({ data: { attentionItems } });
  };
}
