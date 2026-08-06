import { z } from 'zod';
import { isValidTimeFormat } from '../domain/lesson-time';

const timeSchema = z
  .string()
  .refine(isValidTimeFormat, { message: 'Expected time in HH:mm format' });

export const classIdParamSchema = z.object({
  classId: z.uuid(),
});

export const lessonIdParamSchema = z.object({
  id: z.uuid(),
});

export const listLessonsQuerySchema = z.object({
  disciplineId: z.uuid().optional(),
  assessmentPeriodId: z.uuid().optional(),
});

export const createLessonSchema = z.object({
  disciplineId: z.uuid(),
  assessmentPeriodId: z.uuid(),
  date: z.coerce.date(),
  startTime: timeSchema,
  endTime: timeSchema,
  observations: z.string().trim().max(2000).nullish(),
});

export const bulkCreateLessonsSchema = z.object({
  disciplineId: z.uuid(),
  assessmentPeriodId: z.uuid(),
  dates: z.array(z.coerce.date()).min(1).max(200),
  startTime: timeSchema,
  endTime: timeSchema,
  observations: z.string().trim().max(2000).nullish(),
});

export const updateLessonSchema = z
  .object({
    date: z.coerce.date().optional(),
    startTime: timeSchema.optional(),
    endTime: timeSchema.optional(),
    observations: z.string().trim().max(2000).nullish(),
    assessmentPeriodId: z.uuid().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'No fields to update' });
