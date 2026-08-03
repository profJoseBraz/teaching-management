import { z } from 'zod';

const dateOnly = z.coerce.date();

export const idParamSchema = z.object({
  id: z.uuid(),
});

export const courseIdParamSchema = z.object({
  courseId: z.uuid(),
});

export const courseDisciplineParamsSchema = z.object({
  courseId: z.uuid(),
  disciplineId: z.uuid(),
});

// ---------------------------------------------------------------------------
// Academic year
// ---------------------------------------------------------------------------

export const createAcademicYearSchema = z.object({
  year: z.number().int().min(2000).max(2100),
  label: z.string().trim().min(1).max(80).optional(),
  startsOn: dateOnly.optional(),
  endsOn: dateOnly.optional(),
});

export const updateAcademicYearSchema = z
  .object({
    label: z.string().trim().min(1).max(80).nullable(),
    startsOn: dateOnly.nullable(),
    endsOn: dateOnly.nullable(),
  })
  .partial();

// ---------------------------------------------------------------------------
// Course
// ---------------------------------------------------------------------------

export const createCourseSchema = z.object({
  name: z.string().trim().min(2).max(160),
  description: z.string().trim().max(2000).optional(),
});

export const updateCourseSchema = z
  .object({
    name: z.string().trim().min(2).max(160),
    description: z.string().trim().max(2000).nullable(),
  })
  .partial();

// ---------------------------------------------------------------------------
// Discipline
// ---------------------------------------------------------------------------

export const createDisciplineSchema = z.object({
  name: z.string().trim().min(2).max(160),
  description: z.string().trim().max(2000).optional(),
});

export const updateDisciplineSchema = z
  .object({
    name: z.string().trim().min(2).max(160),
    description: z.string().trim().max(2000).nullable(),
  })
  .partial();

// ---------------------------------------------------------------------------
// Course <-> Discipline link
// ---------------------------------------------------------------------------

export const linkDisciplineToCourseSchema = z.object({
  disciplineId: z.uuid(),
});

// ---------------------------------------------------------------------------
// Assessment period
// ---------------------------------------------------------------------------

export const listAssessmentPeriodsQuerySchema = z.object({
  academicYearId: z.uuid(),
});

export const createAssessmentPeriodSchema = z.object({
  academicYearId: z.uuid(),
  classId: z.uuid().optional(),
  name: z.string().trim().min(1).max(80),
  startsOn: dateOnly.optional(),
  endsOn: dateOnly.optional(),
});

export const updateAssessmentPeriodSchema = z
  .object({
    name: z.string().trim().min(1).max(80),
    classId: z.uuid().nullable(),
    startsOn: dateOnly.nullable(),
    endsOn: dateOnly.nullable(),
  })
  .partial();

export const reorderAssessmentPeriodsSchema = z.object({
  academicYearId: z.uuid(),
  orderedIds: z.array(z.uuid()).min(1),
});
