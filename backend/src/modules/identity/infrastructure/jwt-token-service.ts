import jwt from 'jsonwebtoken';
import { env } from '../../../config/env';
import { UnauthorizedError } from '../../../shared/domain/errors';
import type { UserRole } from '../../../shared/domain/user-role';
import type {
  AccessTokenPayload,
  TokenPair,
  TokenService,
} from '../application/ports/token-service';

type JwtPayload = {
  sub: string;
  role: UserRole;
};

export class JwtTokenService implements TokenService {
  issueTokens(payload: AccessTokenPayload): TokenPair {
    const accessToken = jwt.sign(payload, env.JWT_SECRET, {
      expiresIn: env.JWT_EXPIRES_IN as jwt.SignOptions['expiresIn'],
    });

    const refreshToken = jwt.sign(payload, env.REFRESH_TOKEN_SECRET, {
      expiresIn: env.REFRESH_TOKEN_EXPIRES_IN as jwt.SignOptions['expiresIn'],
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: env.JWT_EXPIRES_IN,
    };
  }

  verifyAccessToken(token: string): AccessTokenPayload {
    return this.verify(token, env.JWT_SECRET);
  }

  verifyRefreshToken(token: string): AccessTokenPayload {
    return this.verify(token, env.REFRESH_TOKEN_SECRET);
  }

  private verify(token: string, secret: string): AccessTokenPayload {
    try {
      const decoded = jwt.verify(token, secret) as JwtPayload;
      return { sub: decoded.sub, role: decoded.role };
    } catch {
      throw new UnauthorizedError('Invalid or expired token');
    }
  }
}
