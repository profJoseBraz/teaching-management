import type { NextFunction, Request, Response } from 'express';
import type { AuthContext } from '../application/authorization-policy';
import { UnauthorizedError } from '../domain/errors';
import type { UserRole } from '../domain/user-role';
import type { TokenService } from '../../modules/identity/application/ports/token-service';

declare global {
  namespace Express {
    interface Request {
      auth?: AuthContext;
    }
  }
}

export type AuthMiddleware = (req: Request, res: Response, next: NextFunction) => void;

export function createAuthMiddleware(tokenService: TokenService): AuthMiddleware {
  return (req, _res, next) => {
    try {
      const header = req.headers.authorization;
      if (!header?.startsWith('Bearer ')) {
        throw new UnauthorizedError('Missing bearer token');
      }

      const token = header.slice('Bearer '.length).trim();
      const payload = tokenService.verifyAccessToken(token);

      req.auth = {
        userId: payload.sub,
        role: payload.role as UserRole,
        teacherId: payload.sub,
      };

      next();
    } catch (error) {
      next(error);
    }
  };
}
