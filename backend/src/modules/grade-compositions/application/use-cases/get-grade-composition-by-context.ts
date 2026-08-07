import type { ClassDisciplineGateway } from '../../../../shared/application/ports/class-discipline-gateway';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import type { AssessmentPeriodGateway } from '../../../../shared/application/ports/assessment-period-gateway';
import { ForbiddenError, NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { EvaluationModelRepository } from '../../../evaluation-models/application/ports/evaluation-model-repository';
import type { CompositionSyncResult } from '../ports/grade-composition-repository';
import type { GradeCompositionRepository } from '../ports/grade-composition-repository';
import type { EligibleActivity, GradeComposition } from '../../domain/grade-composition';

export type GetGradeCompositionByContextResult = {
  composition: GradeComposition | null;
  eligibleActivities: EligibleActivity[];
  sync: CompositionSyncResult | null;
};

export class GetGradeCompositionByContextUseCase {
  constructor(
    private readonly compositions: GradeCompositionRepository,
    private readonly evaluationModels: EvaluationModelRepository,
    private readonly classOwnership: ClassOwnershipChecker,
    private readonly classDisciplines: ClassDisciplineGateway,
    private readonly assessmentPeriods: AssessmentPeriodGateway,
  ) {}

  async execute(input: {
    teacherId: string;
    classId: string;
    disciplineId: string;
    assessmentPeriodId: string;
  }): Promise<GetGradeCompositionByContextResult> {
    const owned = await this.classOwnership.isOwnedByTeacher(input.classId, input.teacherId);
    if (!owned) {
      throw new ForbiddenError('Class not found for this teacher');
    }

    const linked = await this.classDisciplines.isLinked(
      input.teacherId,
      input.classId,
      input.disciplineId,
    );
    if (!linked) {
      throw new ValidationError('Discipline is not linked to this class');
    }

    await this.assessmentPeriods.assertUsableForClass({
      teacherId: input.teacherId,
      classId: input.classId,
      assessmentPeriodId: input.assessmentPeriodId,
    });

    const eligibleActivities = await this.compositions.listEligibleActivities(
      input.teacherId,
      input.classId,
      input.disciplineId,
      input.assessmentPeriodId,
    );

    let composition = await this.compositions.findByContext(
      input.teacherId,
      input.classId,
      input.disciplineId,
      input.assessmentPeriodId,
    );

    let sync: CompositionSyncResult | null = null;

    if (composition) {
      const model = await this.evaluationModels.findById(
        input.teacherId,
        composition.evaluationModelId,
      );
      if (!model) {
        throw new NotFoundError('Evaluation model linked to composition was not found');
      }

      const synced = await this.compositions.syncGroupsWithModel(
        input.teacherId,
        composition.id,
      );
      composition = synced.composition;
      sync = synced.sync;
    }

    return { composition, eligibleActivities, sync };
  }
}
