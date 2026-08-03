import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { DashboardController } from './dashboard.controller';
import { dashboardQuerySchema } from './dashboard.schemas';

/** Rotas devem ser montadas na raiz do router de API (paths já incluem o prefixo completo). */
export function createDashboardRoutes(controller: DashboardController, authMiddleware: AuthMiddleware): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/dashboard',
    validate(dashboardQuerySchema, 'query'),
    asyncHandler(controller.getDashboard),
  );
  router.get(
    '/attention-items',
    validate(dashboardQuerySchema, 'query'),
    asyncHandler(controller.getAttentionItems),
  );

  return router;
}
