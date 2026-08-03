import type { Request, Response } from 'express';
import type { CompleteAttendanceUseCase } from '../application/use-cases/complete-attendance';
import type { GetAttendanceSheetUseCase } from '../application/use-cases/get-attendance-sheet';
import type { SaveAttendanceUseCase } from '../application/use-cases/save-attendance';

export class AttendanceController {
  constructor(
    private readonly getAttendanceSheetUseCase: GetAttendanceSheetUseCase,
    private readonly saveAttendanceUseCase: SaveAttendanceUseCase,
    private readonly completeAttendanceUseCase: CompleteAttendanceUseCase,
  ) {}

  getSheet = async (req: Request, res: Response): Promise<void> => {
    const { lessonId } = req.params as { lessonId: string };
    const sheet = await this.getAttendanceSheetUseCase.execute(lessonId, req.auth!.teacherId);
    res.status(200).json({ data: sheet });
  };

  save = async (req: Request, res: Response): Promise<void> => {
    const { lessonId } = req.params as { lessonId: string };
    const { records } = req.body as {
      records: { studentId: string; status: 'PRESENT' | 'ABSENT' | 'LATE'; observations?: string | null }[];
    };
    const sheet = await this.saveAttendanceUseCase.execute(lessonId, req.auth!.teacherId, records);
    res.status(200).json({ data: sheet });
  };

  complete = async (req: Request, res: Response): Promise<void> => {
    const { lessonId } = req.params as { lessonId: string };
    const sheet = await this.completeAttendanceUseCase.execute(lessonId, req.auth!.teacherId);
    res.status(200).json({ data: sheet });
  };
}
