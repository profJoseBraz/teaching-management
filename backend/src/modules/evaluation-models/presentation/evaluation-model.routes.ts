import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { EvaluationModelController } from './evaluation-model.controller';
import {
  createEvaluationModelItemSchema,
  createEvaluationModelSchema,
  idParamSchema,
  listEvaluationModelsQuerySchema,
  modelItemParamsSchema,
  reorderEvaluationModelItemsSchema,
  updateEvaluationModelItemSchema,
  updateEvaluationModelSchema,
} from './evaluation-model.schemas';

export function createEvaluationModelRoutes(
  controller: EvaluationModelController,
  authMiddleware: AuthMiddleware,
): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/evaluation-models',
    validate(listEvaluationModelsQuerySchema, 'query'),
    asyncHandler(controller.list),
  );
  router.post(
    '/evaluation-models',
    validate(createEvaluationModelSchema),
    asyncHandler(controller.create),
  );
  router.get(
    '/evaluation-models/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.get),
  );
  router.patch(
    '/evaluation-models/:id',
    validate(idParamSchema, 'params'),
    validate(updateEvaluationModelSchema),
    asyncHandler(controller.update),
  );
  router.delete(
    '/evaluation-models/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.softDelete),
  );
  router.post(
    '/evaluation-models/:id/deactivate',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.deactivate),
  );

  router.post(
    '/evaluation-models/:id/items',
    validate(idParamSchema, 'params'),
    validate(createEvaluationModelItemSchema),
    asyncHandler(controller.createItem),
  );
  router.patch(
    '/evaluation-models/:id/items/:itemId',
    validate(modelItemParamsSchema, 'params'),
    validate(updateEvaluationModelItemSchema),
    asyncHandler(controller.updateItem),
  );
  router.delete(
    '/evaluation-models/:id/items/:itemId',
    validate(modelItemParamsSchema, 'params'),
    asyncHandler(controller.softDeleteItem),
  );
  router.put(
    '/evaluation-models/:id/items/reorder',
    validate(idParamSchema, 'params'),
    validate(reorderEvaluationModelItemsSchema),
    asyncHandler(controller.reorderItems),
  );

  return router;
}
