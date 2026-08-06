import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { AgendaController } from './agenda.controller';
import {
  createAgendaNoteSchema,
  idParamSchema,
  listAgendaNotesQuerySchema,
  updateAgendaNoteSchema,
} from './agenda.schemas';

export function createAgendaRoutes(
  controller: AgendaController,
  authMiddleware: AuthMiddleware,
): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/agenda-notes',
    validate(listAgendaNotesQuerySchema, 'query'),
    asyncHandler(controller.list),
  );
  router.post('/agenda-notes', validate(createAgendaNoteSchema), asyncHandler(controller.create));
  router.get(
    '/agenda-notes/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.get),
  );
  router.patch(
    '/agenda-notes/:id',
    validate(idParamSchema, 'params'),
    validate(updateAgendaNoteSchema),
    asyncHandler(controller.update),
  );
  router.delete(
    '/agenda-notes/:id',
    validate(idParamSchema, 'params'),
    asyncHandler(controller.remove),
  );

  return router;
}
