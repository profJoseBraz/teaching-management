import { z } from 'zod';

export const idParamSchema = z.object({
  id: z.uuid(),
});

export const modelItemParamsSchema = z.object({
  id: z.uuid(),
  itemId: z.uuid(),
});

const optionalBooleanQuery = z
  .enum(['true', 'false'])
  .optional()
  .transform((value) => (value === undefined ? undefined : value === 'true'));

export const listEvaluationModelsQuerySchema = z.object({
  includeInactive: optionalBooleanQuery,
});

const itemInputSchema = z.object({
  name: z.string().trim().min(1).max(160),
  maxScore: z.coerce.number().positive().max(9999.99),
  sortOrder: z.coerce.number().int().min(0).optional(),
});

export const createEvaluationModelSchema = z.object({
  name: z.string().trim().min(1).max(160),
  description: z.string().trim().max(5000).nullable().optional(),
  sortOrder: z.coerce.number().int().min(0).optional(),
  items: z.array(itemInputSchema).max(50).optional(),
});

export const updateEvaluationModelSchema = z
  .object({
    name: z.string().trim().min(1).max(160),
    description: z.string().trim().max(5000).nullable(),
    isActive: z.boolean(),
    sortOrder: z.coerce.number().int().min(0),
  })
  .partial()
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Informe ao menos um campo para atualizar',
  });

export const createEvaluationModelItemSchema = z
  .object({
    name: z.string().trim().min(1).max(160),
    maxScore: z.coerce.number().positive().max(9999.99),
    sortOrder: z.coerce.number().int().min(0).optional(),
    isRecovery: z.boolean().optional(),
    recoversItemId: z.uuid().nullable().optional(),
  })
  .superRefine((value, ctx) => {
    if (value.isRecovery && !value.recoversItemId) {
      ctx.addIssue({
        code: 'custom',
        path: ['recoversItemId'],
        message: 'Informe o item regular recuperado',
      });
    }
  });

export const updateEvaluationModelItemSchema = z
  .object({
    name: z.string().trim().min(1).max(160),
    maxScore: z.coerce.number().positive().max(9999.99),
    sortOrder: z.coerce.number().int().min(0),
    isRecovery: z.boolean(),
    recoversItemId: z.uuid().nullable(),
  })
  .partial()
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Informe ao menos um campo para atualizar',
  });

export const reorderEvaluationModelItemsSchema = z.object({
  itemIds: z.array(z.uuid()).min(1).max(50),
});
