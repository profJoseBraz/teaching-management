import type { AssessmentPeriodGateway } from '../../../../shared/application/ports/assessment-period-gateway';
import type { ClassDisciplineGateway } from '../../../../shared/application/ports/class-discipline-gateway';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from '../../../../shared/domain/errors';
import type { EvaluationModelRepository } from '../../../evaluation-models/application/ports/evaluation-model-repository';
import type {
  GradeCompositionRepository,
  UpsertGroupInput,
} from '../ports/grade-composition-repository';
import type { GradeComposition } from '../../domain/grade-composition';

export class UpsertGradeCompositionUseCase {
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
    evaluationModelId: string;
    groups: UpsertGroupInput[];
  }): Promise<GradeComposition> {
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

    const model = await this.evaluationModels.findById(
      input.teacherId,
      input.evaluationModelId,
    );
    if (!model) {
      throw new NotFoundError('Evaluation model not found');
    }
    if (!model.isActive) {
      const existing = await this.compositions.findByContext(
        input.teacherId,
        input.classId,
        input.disciplineId,
        input.assessmentPeriodId,
      );
      if (!existing || existing.evaluationModelId !== model.id) {
        throw new ValidationError('Cannot associate an inactive evaluation model');
      }
    }

    const existing = await this.compositions.findByContext(
      input.teacherId,
      input.classId,
      input.disciplineId,
      input.assessmentPeriodId,
    );
    if (existing?.status === 'FINALIZED') {
      throw new ConflictError('Finalized grade composition cannot be modified');
    }

    const modelItemIds = new Set(model.items.map((item) => item.id));
    if (input.groups.length === 0) {
      throw new ValidationError('At least one composition group is required');
    }

    const seenItems = new Set<string>();
    const seenActivities = new Set<string>();

    const eligible = await this.compositions.listEligibleActivities(
      input.teacherId,
      input.classId,
      input.disciplineId,
      input.assessmentPeriodId,
    );
    const eligibleIds = new Set(eligible.map((activity) => activity.id));

    for (const group of input.groups) {
      if (!modelItemIds.has(group.evaluationModelItemId)) {
        throw new ValidationError('Group references an item that does not belong to the model');
      }
      if (seenItems.has(group.evaluationModelItemId)) {
        throw new ValidationError('Duplicate evaluation model item in groups');
      }
      seenItems.add(group.evaluationModelItemId);

      if (group.calculationMethod === 'WEIGHTED_AVERAGE' && group.activities.length === 0) {
        throw new ValidationError('Weighted average groups must include activities with weights');
      }

      for (const activity of group.activities) {
        if (!eligibleIds.has(activity.activityId)) {
          throw new ValidationError(
            'Activity is not eligible for this class, discipline and assessment period',
          );
        }
        if (seenActivities.has(activity.activityId)) {
          throw new ValidationError('An activity can belong to only one composition group');
        }
        seenActivities.add(activity.activityId);

        if (group.calculationMethod === 'WEIGHTED_AVERAGE') {
          if (activity.weight === undefined || activity.weight === null || activity.weight <= 0) {
            throw new ValidationError(
              'Weight is required and must be greater than zero for weighted average',
            );
          }
        }
      }
    }

    for (const item of model.items) {
      if (!seenItems.has(item.id)) {
        throw new ValidationError('All evaluation model items must have a corresponding group');
      }
    }

    return this.compositions.upsert({
      teacherId: input.teacherId,
      classId: input.classId,
      disciplineId: input.disciplineId,
      assessmentPeriodId: input.assessmentPeriodId,
      evaluationModelId: input.evaluationModelId,
      groups: input.groups.map((group) => ({
        evaluationModelItemId: group.evaluationModelItemId,
        calculationMethod: group.calculationMethod,
        activities: group.activities.map((activity) => ({
          activityId: activity.activityId,
          weight:
            group.calculationMethod === 'WEIGHTED_AVERAGE' ? (activity.weight ?? null) : null,
        })),
      })),
    });
  }
}
