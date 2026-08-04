import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { StudentController } from './student.controller';
import {
  bulkCreateStudentsSchema,
  createStudentSchema,
  createStudentsBatchSchema,
  idParamSchema,
  listStudentsQuerySchema,
  previewStudentPasteSchema,
  updateStudentSchema,
} from './student.schemas';

export function createStudentRoutes(
  controller: StudentController,
  authMiddleware: AuthMiddleware,
): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get('/students', validate(listStudentsQuerySchema, 'query'), asyncHandler(controller.list));
  router.post('/students', validate(createStudentSchema), asyncHandler(controller.create));
  router.post(
    '/students/bulk/preview',
    validate(previewStudentPasteSchema),
    asyncHandler(controller.previewPaste),
  );
  router.post(
    '/students/bulk',
    validate(bulkCreateStudentsSchema),
    asyncHandler(controller.bulkCreate),
  );
  router.post(
    '/students/batch',
    validate(createStudentsBatchSchema),
    asyncHandler(controller.createBatch),
  );
  router.get(
    '/students/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.get),
  );
  router.patch(
    '/students/:id',
    validate(idParamSchema, 'params'),
    validate(updateStudentSchema),
    asyncHandler(controller.update),
  );
  router.delete(
    '/students/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.remove),
  );

  return router;
}
