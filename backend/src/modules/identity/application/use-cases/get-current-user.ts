import { NotFoundError } from '../../../../shared/domain/errors';
import { toPublicUser, type PublicUser } from '../../domain/user';
import type { UserRepository } from '../ports/user-repository';

export class GetCurrentUserUseCase {
  constructor(private readonly users: UserRepository) {}

  async execute(userId: string): Promise<PublicUser> {
    const user = await this.users.findById(userId);

    if (!user || user.deletedAt || !user.isActive) {
      throw new NotFoundError('User not found');
    }

    return toPublicUser(user);
  }
}
