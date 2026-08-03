import type { NextFunction, Request, Response } from 'express';
import type { ZodType } from 'zod';

type RequestTarget = 'body' | 'query' | 'params';

export function validate(schema: ZodType, target: RequestTarget = 'body') {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const parsed = schema.parse(req[target]);
    // No Express 5, `req.query` é um getter sem setter (redefinido a cada acesso a
    // partir da URL). `defineProperty` substitui o acessor por um valor gravável,
    // evitando o TypeError "Cannot set property query of ... which has only a getter".
    Object.defineProperty(req, target, {
      value: parsed,
      writable: true,
      configurable: true,
      enumerable: true,
    });
    next();
  };
}
