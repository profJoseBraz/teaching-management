import { z } from 'zod';

export const classIdParamSchema = z.object({
  classId: z.uuid(),
});

export const contentIdParamSchema = z.object({
  id: z.uuid(),
});

export const lessonContentParamSchema = z.object({
  lessonId: z.uuid(),
});

export const lessonContentUnlinkParamSchema = z.object({
  lessonId: z.uuid(),
  contentId: z.uuid(),
});

export const listContentsQuerySchema = z.object({
  status: z.enum(['IN_PROGRESS', 'COMPLETED']).optional(),
  disciplineId: z.uuid().optional(),
  assessmentPeriodId: z.uuid().optional(),
});

export const createContentSchema = z.object({
  disciplineId: z.uuid(),
  assessmentPeriodId: z.uuid(),
  title: z.string().trim().min(2).max(200),
  description: z.string().trim().max(4000).nullish(),
});

export const updateContentSchema = z
  .object({
    title: z.string().trim().min(2).max(200).optional(),
    description: z.string().trim().max(4000).nullish(),
    assessmentPeriodId: z.uuid().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'No fields to update' });

export const linkContentToLessonBodySchema = z.object({
  contentId: z.uuid(),
});
