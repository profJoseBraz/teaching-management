import { z } from 'zod';

export const idParamSchema = z.object({
  id: z.uuid(),
});

export const getGradeCompositionQuerySchema = z.object({
  classId: z.uuid(),
  disciplineId: z.uuid(),
  assessmentPeriodId: z.uuid(),
});

const groupActivitySchema = z.object({
  activityId: z.uuid(),
  weight: z.coerce.number().positive().max(9999).nullable().optional(),
});

const groupSchema = z.object({
  evaluationModelItemId: z.uuid(),
  calculationMethod: z.enum(['SIMPLE_AVERAGE', 'WEIGHTED_AVERAGE']),
  activities: z.array(groupActivitySchema).max(200).default([]),
});

export const upsertGradeCompositionSchema = z.object({
  classId: z.uuid(),
  disciplineId: z.uuid(),
  assessmentPeriodId: z.uuid(),
  evaluationModelId: z.uuid(),
  groups: z.array(groupSchema).min(1).max(50),
});
