import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { ClassController } from './class.controller';
import {
  classDisciplineParamsSchema,
  classIdParamSchema,
  classStudentParamsSchema,
  createClassSchema,
  enrollStudentSchema,
  idParamSchema,
  linkDisciplineToClassSchema,
  listClassesQuerySchema,
  updateClassSchema,
} from './class.schemas';

export function createClassRoutes(controller: ClassController, authMiddleware: AuthMiddleware): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get('/classes', validate(listClassesQuerySchema, 'query'), asyncHandler(controller.list));
  router.post('/classes', validate(createClassSchema), asyncHandler(controller.create));
  router.get('/classes/:id', validate(idParamSchema, 'params'), asyncHandler(controller.get));
  router.patch(
    '/classes/:id',
    validate(idParamSchema, 'params'),
    validate(updateClassSchema),
    asyncHandler(controller.update),
  );
  router.post(
    '/classes/:id/archive',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.archive),
  );

  router.get(
    '/classes/:classId/enrollments',
    validate(classIdParamSchema, 'params'),
    asyncHandler(controller.listEnrollments),
  );
  router.post(
    '/classes/:classId/enrollments',
    validate(classIdParamSchema, 'params'),
    validate(enrollStudentSchema),
    asyncHandler(controller.enrollStudent),
  );
  router.delete(
    '/classes/:classId/enrollments/:studentId',
    validate(classStudentParamsSchema, 'params'),
    asyncHandler(controller.unenrollStudent),
  );

  router.get(
    '/classes/:classId/disciplines',
    validate(classIdParamSchema, 'params'),
    asyncHandler(controller.listDisciplines),
  );
  router.post(
    '/classes/:classId/disciplines',
    validate(classIdParamSchema, 'params'),
    validate(linkDisciplineToClassSchema),
    asyncHandler(controller.linkDiscipline),
  );
  router.delete(
    '/classes/:classId/disciplines/:disciplineId',
    validate(classDisciplineParamsSchema, 'params'),
    asyncHandler(controller.unlinkDiscipline),
  );

  return router;
}
