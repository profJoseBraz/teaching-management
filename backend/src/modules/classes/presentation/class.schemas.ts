import { z } from 'zod';
import { CLASS_SHIFTS, CLASS_STATUSES } from '../domain/class';

export const idParamSchema = z.object({
  id: z.uuid(),
});

export const classIdParamSchema = z.object({
  classId: z.uuid(),
});

export const classStudentParamsSchema = z.object({
  classId: z.uuid(),
  studentId: z.uuid(),
});

export const classDisciplineParamsSchema = z.object({
  classId: z.uuid(),
  disciplineId: z.uuid(),
});

export const listClassesQuerySchema = z.object({
  academicYearId: z.uuid().optional(),
  courseId: z.uuid().optional(),
  disciplineId: z.uuid().optional(),
  status: z.enum(CLASS_STATUSES).optional(),
});

/**
 * `disciplineIds` é a forma preferida (mín. 1). `disciplineId` singular é aceito por
 * compatibilidade e normalizado junto de `disciplineIds` antes de chegar ao Use Case.
 */
export const createClassSchema = z
  .object({
    academicYearId: z.uuid(),
    courseId: z.uuid(),
    name: z.string().trim().min(1).max(120),
    shift: z.enum(CLASS_SHIFTS).optional(),
    disciplineId: z.uuid().optional(),
    disciplineIds: z.array(z.uuid()).optional(),
  })
  .transform(({ disciplineId, disciplineIds, ...rest }) => ({
    ...rest,
    disciplineIds: Array.from(new Set([...(disciplineIds ?? []), ...(disciplineId ? [disciplineId] : [])])),
  }))
  .refine((data) => data.disciplineIds.length > 0, {
    message: 'At least one disciplineId is required',
    path: ['disciplineIds'],
  });

export const updateClassSchema = z
  .object({
    name: z.string().trim().min(1).max(120),
    shift: z.enum(CLASS_SHIFTS).nullable(),
  })
  .partial();

export const enrollStudentSchema = z.object({
  studentId: z.uuid(),
});

export const bulkEnrollStudentsSchema = z.object({
  studentIds: z.array(z.uuid()).min(1).max(500),
});

export const linkDisciplineToClassSchema = z.object({
  disciplineId: z.uuid(),
});
