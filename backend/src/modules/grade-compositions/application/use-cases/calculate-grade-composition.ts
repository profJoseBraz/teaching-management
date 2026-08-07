import { NotFoundError } from '../../../../shared/domain/errors';
import {
  calculateFinalAverage,
  calculateGroupConvertedScore,
  considerBestScore,
} from '../../domain/grade-calculator';
import type {
  CalculateCompositionResult,
  GradeCompositionRepository,
} from '../ports/grade-composition-repository';

export class CalculateGradeCompositionUseCase {
  constructor(private readonly compositions: GradeCompositionRepository) {}

  async execute(teacherId: string, compositionId: string): Promise<CalculateCompositionResult> {
    const existing = await this.compositions.findById(teacherId, compositionId);
    if (!existing) {
      throw new NotFoundError('Grade composition not found');
    }

    // Garante grupos alinhados ao modelo antes de calcular (exceto FINALIZED).
    if (existing.status !== 'FINALIZED') {
      await this.compositions.syncGroupsWithModel(teacherId, compositionId);
    }

    const data = await this.compositions.loadCalculationData(teacherId, compositionId);
    const { composition, students, scoresByStudentActivity, activityMaxScores, eligibleActivityIds } =
      data;

    const groupedActivityIds = new Set(
      composition.groups.flatMap((group) => group.activities.map((a) => a.activityId)),
    );
    const ungroupedActivityCount = eligibleActivityIds.filter(
      (id) => !groupedActivityIds.has(id),
    ).length;

    const emptyGroups = composition.groups
      .filter((group) => group.activities.length === 0)
      .map((group) => ({
        evaluationModelItemId: group.evaluationModelItemId,
        itemName: group.itemName,
      }));
    const emptyGroupItemIds = new Set(
      emptyGroups.map((group) => group.evaluationModelItemId),
    );

    const studentRows = students.map((student) => {
      const studentScores = scoresByStudentActivity.get(student.id) ?? new Map();

      const rawGroups = composition.groups.map((group) => {
        const activities = group.activities.map((activity) => {
          const maxScore =
            activityMaxScores.get(activity.activityId) ?? activity.activityMaxScore ?? 100;
          return {
            activityId: activity.activityId,
            title: activity.activityTitle ?? 'Atividade',
            description: activity.activityDescription ?? null,
            maxScore,
            score: studentScores.get(activity.activityId) ?? null,
            weight: activity.weight,
          };
        });

        const entries = activities.map((activity) => ({
          score: activity.score,
          activityMaxScore: activity.maxScore,
          weight: activity.weight,
        }));

        return {
          evaluationModelItemId: group.evaluationModelItemId,
          itemName: group.itemName,
          itemMaxScore: group.itemMaxScore,
          itemSortOrder: group.itemSortOrder,
          calculationMethod: group.calculationMethod,
          isRecovery: group.isRecovery,
          recoversItemId: group.recoversItemId,
          convertedScore: calculateGroupConvertedScore(
            group.calculationMethod,
            entries,
            group.itemMaxScore,
          ),
          activities,
        };
      });

      const recoveryByRegularId = new Map<string, number | null>();
      for (const group of rawGroups) {
        if (group.isRecovery && group.recoversItemId) {
          recoveryByRegularId.set(group.recoversItemId, group.convertedScore);
        }
      }

      const groups = rawGroups.map((group) => {
        const consideredScore = group.isRecovery
          ? group.convertedScore
          : considerBestScore(
              group.convertedScore,
              recoveryByRegularId.get(group.evaluationModelItemId) ?? null,
            );

        return {
          ...group,
          consideredScore,
        };
      });

      const finalAverage = calculateFinalAverage(
        groups
          .filter((group) => !emptyGroupItemIds.has(group.evaluationModelItemId))
          .map((group) => ({
            consideredScore: group.consideredScore,
            itemMaxScore: group.itemMaxScore,
            isRecovery: group.isRecovery,
          })),
      );

      return {
        studentId: student.id,
        studentName: student.name,
        groups,
        finalAverage,
      };
    });

    return {
      compositionId: composition.id,
      updatedAt: composition.updatedAt,
      students: studentRows,
      warnings: {
        emptyGroups,
        ungroupedActivityCount,
      },
    };
  }
}
