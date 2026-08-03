import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { AttendanceController } from './attendance.controller';
import { lessonIdParamSchema, saveAttendanceSchema } from './attendance.schemas';

/** Rotas devem ser montadas na raiz do router de API (paths já incluem o prefixo completo). */
export function createAttendanceRoutes(
  controller: AttendanceController,
  authMiddleware: AuthMiddleware,
): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/lessons/:lessonId/attendance',
    validate(lessonIdParamSchema, 'params'),
    asyncHandler(controller.getSheet),
  );
  router.put(
    '/lessons/:lessonId/attendance',
    validate(lessonIdParamSchema, 'params'),
    validate(saveAttendanceSchema),
    asyncHandler(controller.save),
  );
  router.post(
    '/lessons/:lessonId/attendance/complete',
    validate(lessonIdParamSchema, 'params'),
    asyncHandler(controller.complete),
  );

  return router;
}
