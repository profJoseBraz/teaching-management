import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { StudentController } from './student.controller';
import {
  createStudentSchema,
  idParamSchema,
  listStudentsQuerySchema,
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
