import { UnauthorizedError } from '../../../../shared/domain/errors';
import type { TokenPair, TokenService } from '../ports/token-service';
import type { UserRepository } from '../ports/user-repository';

export type RefreshTokensInput = {
  refreshToken: string;
};

export type RefreshTokensOutput = {
  tokens: TokenPair;
};

/**
 * Renova o par de tokens a partir de um refresh token válido.
 * Stateless (JWT): verifica assinatura/expiração, confere usuário ativo e reemite.
 */
export class RefreshTokensUseCase {
  constructor(
    private readonly users: UserRepository,
    private readonly tokens: TokenService,
  ) {}

  async execute(input: RefreshTokensInput): Promise<RefreshTokensOutput> {
    let payload;
    try {
      payload = this.tokens.verifyRefreshToken(input.refreshToken);
    } catch {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    const user = await this.users.findById(payload.sub);
    if (!user || user.deletedAt || !user.isActive) {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    const tokens = this.tokens.issueTokens({
      sub: user.id,
      role: user.role,
    });

    return { tokens };
  }
}
