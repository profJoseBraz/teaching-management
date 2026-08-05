import { z } from 'zod';

const ACTIVITY_CATEGORIES = [
  'EXERCISE',
  'ASSIGNMENT',
  'PROJECT',
  'RESEARCH',
  'SEMINAR',
  'EXAM',
  'OTHER',
] as const;

export const classIdParamSchema = z.object({
  classId: z.uuid(),
});

export const activityIdParamSchema = z.object({
  id: z.uuid(),
});

export const activityGroupsParamSchema = z.object({
  id: z.uuid(),
});

export const activityGroupGradeParamSchema = z.object({
  activityId: z.uuid(),
  groupId: z.uuid(),
});

export const submissionIdParamSchema = z.object({
  id: z.uuid(),
});

/** Tag livre: trim, colapsa espaços; vazio → null. */
const activityTagSchema = z.preprocess((value) => {
  if (value == null || value === '') return null;
  if (typeof value !== 'string') return value;
  const normalized = value.trim().replace(/\s+/g, ' ');
  return normalized.length === 0 ? null : normalized;
}, z.string().max(80).nullable());

export const listActivitiesQuerySchema = z.object({
  disciplineId: z.uuid().optional(),
  tag: z.string().trim().min(1).max(80).optional(),
});

/**
 * `disciplineIds` é a forma preferida (mín. 1 sem aula de origem).
 * `disciplineId` singular é aceito por compatibilidade e normalizado em `disciplineIds`.
 */
export const createActivitySchema = z
  .object({
    /** Opcional — atividade pode existir sem aula de origem. */
    originLessonId: z.uuid().nullish(),
    disciplineId: z.uuid().optional(),
    disciplineIds: z.array(z.uuid()).optional(),
    assessmentPeriodId: z.uuid().nullish(),
    title: z.string().trim().min(2).max(200),
    description: z.string().trim().max(5000).nullish(),
    tag: activityTagSchema.optional(),
    category: z.enum(ACTIVITY_CATEGORIES).default('ASSIGNMENT'),
    mode: z.enum(['INDIVIDUAL', 'GROUP']).default('INDIVIDUAL'),
    gradeMode: z.enum(['SHARED', 'INDIVIDUAL']).default('INDIVIDUAL'),
    maxScore: z.coerce.number().positive().max(1000).default(100),
    dueDate: z.coerce.date(),
  })
  .transform(({ disciplineId, disciplineIds, ...rest }) => ({
    ...rest,
    disciplineIds: Array.from(
      new Set([...(disciplineIds ?? []), ...(disciplineId ? [disciplineId] : [])]),
    ),
  }))
  .refine((data) => Boolean(data.originLessonId) || data.disciplineIds.length > 0, {
    message: 'At least one disciplineId is required when originLessonId is omitted',
    path: ['disciplineIds'],
  });

export const updateActivitySchema = z
  .object({
    assessmentPeriodId: z.uuid().nullish(),
    title: z.string().trim().min(2).max(200).optional(),
    description: z.string().trim().max(5000).nullish(),
    tag: activityTagSchema.optional(),
    category: z.enum(ACTIVITY_CATEGORIES).optional(),
    mode: z.enum(['INDIVIDUAL', 'GROUP']).optional(),
    gradeMode: z.enum(['SHARED', 'INDIVIDUAL']).optional(),
    maxScore: z.coerce.number().positive().max(1000).optional(),
    dueDate: z.coerce.date().optional(),
    disciplineId: z.uuid().optional(),
    disciplineIds: z.array(z.uuid()).optional(),
  })
  .transform(({ disciplineId, disciplineIds, ...rest }) => {
    const hasDisciplinePatch = disciplineIds !== undefined || disciplineId !== undefined;
    return {
      ...rest,
      ...(hasDisciplinePatch
        ? {
            disciplineIds: Array.from(
              new Set([...(disciplineIds ?? []), ...(disciplineId ? [disciplineId] : [])]),
            ),
          }
        : {}),
    };
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'No fields to update' })
  .refine((data) => data.disciplineIds === undefined || data.disciplineIds.length > 0, {
    message: 'At least one disciplineId is required',
    path: ['disciplineIds'],
  });

export const createActivityGroupsSchema = z.object({
  groups: z
    .array(
      z.object({
        name: z.string().trim().min(1).max(120),
        studentIds: z.array(z.uuid()).min(1),
      }),
    )
    .min(1),
});

export const updateSubmissionSchema = z.object({
  status: z.enum(['PENDING', 'SUBMITTED']),
});

export const gradeSubmissionSchema = z.object({
  score: z.coerce.number().min(0),
  observations: z.string().trim().max(2000).nullish(),
});

export const gradeGroupSharedSchema = z.object({
  score: z.coerce.number().min(0),
  observations: z.string().trim().max(2000).nullish(),
});

export const gradeSubmissionsBulkSchema = z.object({
  submissionIds: z.array(z.uuid()).min(1).max(200),
  score: z.coerce.number().min(0),
  observations: z.string().trim().max(2000).nullish(),
});
