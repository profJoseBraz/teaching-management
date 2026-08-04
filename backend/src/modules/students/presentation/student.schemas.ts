import { z } from 'zod';

export const idParamSchema = z.object({
  id: z.uuid(),
});

export const listStudentsQuerySchema = z.object({
  search: z.string().trim().min(1).max(160).optional(),
});

export const createStudentSchema = z.object({
  name: z.string().trim().min(2).max(160),
  registryCode: z.string().trim().max(60).optional(),
  email: z.email().optional(),
  phone: z.string().trim().max(40).optional(),
  notes: z.string().trim().max(4000).optional(),
});

export const bulkCreateStudentsSchema = z.object({
  text: z.string().trim().min(1).max(200_000),
});

export const updateStudentSchema = z
  .object({
    name: z.string().trim().min(2).max(160),
    registryCode: z.string().trim().max(60).nullable(),
    email: z.email().nullable(),
    phone: z.string().trim().max(40).nullable(),
    notes: z.string().trim().max(4000).nullable(),
  })
  .partial();
