import type { User } from '../../domain/user';
import type { UserRole } from '../../../../shared/domain/user-role';

export type CreateUserInput = {
  name: string;
  email: string;
  passwordHash: string;
  role?: UserRole;
};

export interface UserRepository {
  findByEmail(email: string): Promise<User | null>;
  findById(id: string): Promise<User | null>;
  create(input: CreateUserInput): Promise<User>;
}
