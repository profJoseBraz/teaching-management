import type { Request, Response } from 'express';
import type { GradeGroupSharedUseCase } from '../application/use-cases/grade-group-shared';
import type { GradeSubmissionUseCase } from '../application/use-cases/grade-submission';
import type { MarkSubmissionSubmittedUseCase } from '../application/use-cases/mark-submission-submitted';

export class SubmissionController {
  constructor(
    private readonly markSubmissionSubmittedUseCase: MarkSubmissionSubmittedUseCase,
    private readonly gradeSubmissionUseCase: GradeSubmissionUseCase,
    private readonly gradeGroupSharedUseCase: GradeGroupSharedUseCase,
  ) {}

  update = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const submission = await this.markSubmissionSubmittedUseCase.execute(id, req.auth!.teacherId);
    res.status(200).json({ data: submission });
  };

  grade = async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params as { id: string };
    const { score, observations } = req.body as { score: number; observations?: string | null };
    const submission = await this.gradeSubmissionUseCase.execute(id, req.auth!.teacherId, score, observations);
    res.status(200).json({ data: submission });
  };

  gradeGroupShared = async (req: Request, res: Response): Promise<void> => {
    const { activityId, groupId } = req.params as { activityId: string; groupId: string };
    const { score, observations } = req.body as { score: number; observations?: string | null };
    const submissions = await this.gradeGroupSharedUseCase.execute(
      activityId,
      groupId,
      req.auth!.teacherId,
      score,
      observations,
    );
    res.status(200).json({ data: submissions });
  };
}
