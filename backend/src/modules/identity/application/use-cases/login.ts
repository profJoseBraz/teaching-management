import { UnauthorizedError } from '../../../../shared/domain/errors';
import { toPublicUser, type PublicUser } from '../../domain/user';
import type { PasswordHasher } from '../ports/password-hasher';
import type { TokenPair, TokenService } from '../ports/token-service';
import type { UserRepository } from '../ports/user-repository';

export type LoginInput = {
  email: string;
  password: string;
};

export type LoginOutput = {
  user: PublicUser;
  tokens: TokenPair;
};

export class LoginUseCase {
  constructor(
    private readonly users: UserRepository,
    private readonly passwordHasher: PasswordHasher,
    private readonly tokens: TokenService,
  ) {}

  async execute(input: LoginInput): Promise<LoginOutput> {
    const user = await this.users.findByEmail(input.email.toLowerCase().trim());

    if (!user || user.deletedAt || !user.isActive) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const valid = await this.passwordHasher.compare(input.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const tokens = this.tokens.issueTokens({
      sub: user.id,
      role: user.role,
    });

    return {
      user: toPublicUser(user),
      tokens,
    };
  }
}
