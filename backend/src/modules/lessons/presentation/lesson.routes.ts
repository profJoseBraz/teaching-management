import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { LessonController } from './lesson.controller';
import {
  bulkCreateLessonsSchema,
  classIdParamSchema,
  createLessonSchema,
  lessonIdParamSchema,
  listLessonsQuerySchema,
  updateLessonSchema,
} from './lesson.schemas';

/** Rotas devem ser montadas na raiz do router de API (paths já incluem o prefixo completo). */
export function createLessonRoutes(controller: LessonController, authMiddleware: AuthMiddleware): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/classes/:classId/lessons',
    validate(classIdParamSchema, 'params'),
    validate(listLessonsQuerySchema, 'query'),
    asyncHandler(controller.list),
  );
  router.post(
    '/classes/:classId/lessons/bulk',
    validate(classIdParamSchema, 'params'),
    validate(bulkCreateLessonsSchema),
    asyncHandler(controller.bulkCreate),
  );
  router.post(
    '/classes/:classId/lessons',
    validate(classIdParamSchema, 'params'),
    validate(createLessonSchema),
    asyncHandler(controller.create),
  );
  router.get('/lessons/:id', validate(lessonIdParamSchema, 'params'), asyncHandler(controller.get));
  router.patch(
    '/lessons/:id',
    validate(lessonIdParamSchema, 'params'),
    validate(updateLessonSchema),
    asyncHandler(controller.update),
  );
  router.delete('/lessons/:id', validate(lessonIdParamSchema, 'params'), asyncHandler(controller.remove));

  return router;
}
