import { describe, expect, it, vi } from 'vitest';
import { UnauthorizedError } from '../../src/shared/domain/errors';
import { LoginUseCase } from '../../src/modules/identity/application/use-cases/login';
import type { User } from '../../src/modules/identity/domain/user';

describe('LoginUseCase', () => {
  const user: User = {
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Professor',
    email: 'professor@gestao.docente',
    passwordHash: 'hashed',
    role: 'PROFESSOR',
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
    deletedAt: null,
  };

  it('returns tokens for valid credentials', async () => {
    const users = {
      findByEmail: vi.fn().mockResolvedValue(user),
      findById: vi.fn(),
      create: vi.fn(),
    };
    const passwordHasher = {
      hash: vi.fn(),
      compare: vi.fn().mockResolvedValue(true),
    };
    const tokens = {
      issueTokens: vi.fn().mockReturnValue({
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresIn: '15m',
      }),
      verifyAccessToken: vi.fn(),
      verifyRefreshToken: vi.fn(),
    };

    const useCase = new LoginUseCase(users, passwordHasher, tokens);
    const result = await useCase.execute({
      email: 'professor@gestao.docente',
      password: 'Professor@123',
    });

    expect(result.user.email).toBe(user.email);
    expect(result.tokens.accessToken).toBe('access');
    expect(passwordHasher.compare).toHaveBeenCalledWith('Professor@123', 'hashed');
  });

  it('rejects invalid password', async () => {
    const useCase = new LoginUseCase(
      {
        findByEmail: vi.fn().mockResolvedValue(user),
        findById: vi.fn(),
        create: vi.fn(),
      },
      {
        hash: vi.fn(),
        compare: vi.fn().mockResolvedValue(false),
      },
      {
        issueTokens: vi.fn(),
        verifyAccessToken: vi.fn(),
        verifyRefreshToken: vi.fn(),
      },
    );

    await expect(
      useCase.execute({ email: 'professor@gestao.docente', password: 'wrong' }),
    ).rejects.toBeInstanceOf(UnauthorizedError);
  });
});
