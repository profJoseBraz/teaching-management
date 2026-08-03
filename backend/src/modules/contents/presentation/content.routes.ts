import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { ContentController } from './content.controller';
import {
  classIdParamSchema,
  contentIdParamSchema,
  createContentSchema,
  linkContentToLessonBodySchema,
  lessonContentParamSchema,
  lessonContentUnlinkParamSchema,
  listContentsQuerySchema,
  updateContentSchema,
} from './content.schemas';

/** Rotas devem ser montadas na raiz do router de API (paths já incluem o prefixo completo). */
export function createContentRoutes(controller: ContentController, authMiddleware: AuthMiddleware): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/classes/:classId/contents',
    validate(classIdParamSchema, 'params'),
    validate(listContentsQuerySchema, 'query'),
    asyncHandler(controller.list),
  );
  router.post(
    '/classes/:classId/contents',
    validate(classIdParamSchema, 'params'),
    validate(createContentSchema),
    asyncHandler(controller.create),
  );
  router.patch(
    '/contents/:id',
    validate(contentIdParamSchema, 'params'),
    validate(updateContentSchema),
    asyncHandler(controller.update),
  );
  router.post('/contents/:id/complete', validate(contentIdParamSchema, 'params'), asyncHandler(controller.complete));
  router.post('/contents/:id/reopen', validate(contentIdParamSchema, 'params'), asyncHandler(controller.reopen));

  router.post(
    '/lessons/:lessonId/contents',
    validate(lessonContentParamSchema, 'params'),
    validate(linkContentToLessonBodySchema),
    asyncHandler(controller.linkToLesson),
  );
  router.delete(
    '/lessons/:lessonId/contents/:contentId',
    validate(lessonContentUnlinkParamSchema, 'params'),
    asyncHandler(controller.unlinkFromLesson),
  );

  return router;
}
