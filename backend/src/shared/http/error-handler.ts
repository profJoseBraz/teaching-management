import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import {
  ConflictError,
  DomainError,
  ForbiddenError,
  NotFoundError,
  UnauthorizedError,
  ValidationError,
} from '../domain/errors';
import { toErrorBody } from './http-error';

export function errorHandler(error: unknown, _req: Request, res: Response, _next: NextFunction): void {
  if (error instanceof ZodError) {
    res.status(422).json(
      toErrorBody(
        'VALIDATION_ERROR',
        'Validation failed',
        error.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      ),
    );
    return;
  }

  if (error instanceof ValidationError) {
    res.status(422).json(toErrorBody(error.code, error.message, error.details));
    return;
  }

  if (error instanceof UnauthorizedError) {
    res.status(401).json(toErrorBody(error.code, error.message));
    return;
  }

  if (error instanceof ForbiddenError) {
    res.status(403).json(toErrorBody(error.code, error.message));
    return;
  }

  if (error instanceof NotFoundError) {
    res.status(404).json(toErrorBody(error.code, error.message));
    return;
  }

  if (error instanceof ConflictError) {
    res.status(409).json(toErrorBody(error.code, error.message));
    return;
  }

  if (error instanceof DomainError) {
    res.status(400).json(toErrorBody(error.code, error.message));
    return;
  }

  console.error(error);
  res.status(500).json(toErrorBody('INTERNAL_ERROR', 'Internal server error'));
}
