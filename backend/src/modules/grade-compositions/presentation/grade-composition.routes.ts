import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { GradeCompositionController } from './grade-composition.controller';
import {
  getGradeCompositionQuerySchema,
  idParamSchema,
  upsertGradeCompositionSchema,
} from './grade-composition.schemas';

export function createGradeCompositionRoutes(
  controller: GradeCompositionController,
  authMiddleware: AuthMiddleware,
): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/grade-compositions',
    validate(getGradeCompositionQuerySchema, 'query'),
    asyncHandler(controller.getByContext),
  );
  router.put(
    '/grade-compositions',
    validate(upsertGradeCompositionSchema),
    asyncHandler(controller.upsert),
  );
  router.delete(
    '/grade-compositions/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.softDelete),
  );
  router.get(
    '/grade-compositions/:id/calculate',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.calculate),
  );

  return router;
}
