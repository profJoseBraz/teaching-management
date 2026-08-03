import { z } from 'zod';
import { REPORT_TYPES } from '../domain/report';

export const reportTypeParamSchema = z.object({
  reportType: z.enum(REPORT_TYPES),
});

export const reportFiltersQuerySchema = z.object({
  academicYearId: z.uuid().optional(),
  courseId: z.uuid().optional(),
  disciplineId: z.uuid().optional(),
  classId: z.uuid().optional(),
  assessmentPeriodId: z.uuid().optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
  threshold: z.coerce.number().int().positive().optional(),
});
