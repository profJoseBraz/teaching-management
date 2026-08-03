import { ConflictError } from '../../../../shared/domain/errors';
import { toPublicUser, type PublicUser } from '../../domain/user';
import type { PasswordHasher } from '../ports/password-hasher';
import type { TokenPair, TokenService } from '../ports/token-service';
import type { UserRepository } from '../ports/user-repository';

export type RegisterTeacherInput = {
  name: string;
  email: string;
  password: string;
};

export type RegisterTeacherOutput = {
  user: PublicUser;
  tokens: TokenPair;
};

export class RegisterTeacherUseCase {
  constructor(
    private readonly users: UserRepository,
    private readonly passwordHasher: PasswordHasher,
    private readonly tokens: TokenService,
  ) {}

  async execute(input: RegisterTeacherInput): Promise<RegisterTeacherOutput> {
    const email = input.email.toLowerCase().trim();
    const existing = await this.users.findByEmail(email);

    if (existing) {
      throw new ConflictError('Email already registered');
    }

    const passwordHash = await this.passwordHasher.hash(input.password);
    const user = await this.users.create({
      name: input.name.trim(),
      email,
      passwordHash,
      role: 'PROFESSOR',
    });

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
