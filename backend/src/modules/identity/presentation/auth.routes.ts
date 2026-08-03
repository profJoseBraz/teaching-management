import { Router } from 'express';
import { asyncHandler } from '../../../shared/http/async-handler';
import type { AuthMiddleware } from '../../../shared/http/auth.middleware';
import { validate } from '../../../shared/http/validate';
import type { AuthController } from './auth.controller';
import { loginSchema, registerSchema } from './auth.schemas';

export function createAuthRoutes(controller: AuthController, authMiddleware: AuthMiddleware): Router {
  const router = Router();

  router.post('/login', validate(loginSchema), asyncHandler(controller.login));
  router.post('/register', validate(registerSchema), asyncHandler(controller.register));
  router.get('/me', authMiddleware, asyncHandler(controller.me));

  return router;
}
