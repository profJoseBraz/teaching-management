import bcrypt from 'bcryptjs';
import type { PasswordHasher } from '../application/ports/password-hasher';

const ROUNDS = 10;

export class BcryptPasswordHasher implements PasswordHasher {
  hash(plain: string): Promise<string> {
    return bcrypt.hash(plain, ROUNDS);
  }

  compare(plain: string, hash: string): Promise<boolean> {
    return bcrypt.compare(plain, hash);
  }
}
