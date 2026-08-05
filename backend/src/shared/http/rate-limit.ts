import rateLimit from 'express-rate-limit';
import { env } from '../../config/env';

const rateLimitBody = {
  error: {
    code: 'RATE_LIMIT_EXCEEDED',
    message: 'Muitas requisições em pouco tempo. Aguarde um momento e tente novamente.',
  },
};

/**
 * Limite geral da API. Em desenvolvimento fica desligado — o app Flutter
 * (Riverpod) invalida/refetch com frequência e 200/15min trava fluxos reais
 * como marcar várias entregas. Em produção usa RATE_LIMIT_*.
 */
export const apiRateLimit = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) =>
    env.NODE_ENV === 'development' ||
    req.path === '/api/v1/health' ||
    req.path.startsWith('/api/docs'),
  message: rateLimitBody,
});

/** Proteção contra brute-force em login/register — sempre ativo. */
export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: rateLimitBody,
});
