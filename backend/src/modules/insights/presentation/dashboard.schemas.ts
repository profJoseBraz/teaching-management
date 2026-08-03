import { z } from 'zod';

export const dashboardQuerySchema = z.object({
  academicYearId: z.uuid().optional(),
  classId: z.uuid().optional(),
});
