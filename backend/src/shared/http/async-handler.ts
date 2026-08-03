import type { NextFunction, Request, Response } from 'express';

type AsyncRoute<Req extends Request> = (req: Req, res: Response, next: NextFunction) => Promise<void>;

/**
 * Garante que rejeições async caiam no errorHandler.
 * Genérico em `Req` para preservar a tipagem de `req.params`/`req.query` dos controllers.
 */
export function asyncHandler<Req extends Request = Request>(handler: AsyncRoute<Req>) {
  return (req: Req, res: Response, next: NextFunction): void => {
    void handler(req, res, next).catch(next);
  };
}
