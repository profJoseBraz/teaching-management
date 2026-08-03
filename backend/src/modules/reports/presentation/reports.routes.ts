import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { ReportsController } from './reports.controller';
import { reportFiltersQuerySchema, reportTypeParamSchema } from './reports.schemas';

/** Rotas devem ser montadas na raiz do router de API (paths já incluem o prefixo completo). */
export function createReportsRoutes(controller: ReportsController, authMiddleware: AuthMiddleware): Router {
  const router = Router();

  router.use(authMiddleware);

  router.get(
    '/reports/:reportType',
    validate(reportTypeParamSchema, 'params'),
    validate(reportFiltersQuerySchema, 'query'),
    asyncHandler(controller.run),
  );

  return router;
}
