import { z } from 'zod';

export const idParamSchema = z.object({
  id: z.uuid(),
});

const optionalBooleanQuery = z
  .enum(['true', 'false'])
  .optional()
  .transform((value) => (value === undefined ? undefined : value === 'true'));

export const listAgendaNotesQuerySchema = z.object({
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
  search: z.string().trim().min(1).max(160).optional(),
  completed: optionalBooleanQuery,
});

export const createAgendaNoteSchema = z.object({
  date: z.coerce.date(),
  content: z.string().trim().min(1).max(50_000),
  completed: z.boolean().optional(),
});

export const updateAgendaNoteSchema = z
  .object({
    date: z.coerce.date(),
    content: z.string().trim().min(1).max(50_000),
    completed: z.boolean(),
  })
  .partial()
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Informe ao menos um campo para atualizar',
  });
