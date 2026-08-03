import type { UserRole } from '../../../../shared/domain/user-role';

export type AccessTokenPayload = {
  sub: string;
  role: UserRole;
};

export type TokenPair = {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
};

export interface TokenService {
  issueTokens(payload: AccessTokenPayload): TokenPair;
  verifyAccessToken(token: string): AccessTokenPayload;
  verifyRefreshToken(token: string): AccessTokenPayload;
}
