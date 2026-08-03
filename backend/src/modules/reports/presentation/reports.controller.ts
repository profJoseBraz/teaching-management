import type { Request, Response } from 'express';
import type { RunReportUseCase } from '../application/use-cases/run-report';
import type { ReportFilters, ReportType } from '../domain/report';

type ReportTypeParams = { reportType: ReportType };

/** Adapta HTTP <-> RunReportUseCase. Nenhuma regra de negócio aqui. */
export class ReportsController {
  constructor(private readonly runReportUseCase: RunReportUseCase) {}

  run = async (req: Request, res: Response): Promise<void> => {
    const teacherId = req.auth!.teacherId;
    const { reportType } = req.params as ReportTypeParams;
    const filters = req.query as ReportFilters;

    const result = await this.runReportUseCase.execute({ teacherId, reportType, filters });

    res.status(200).json({ data: result });
  };
}
