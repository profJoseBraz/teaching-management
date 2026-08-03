import type { UserRole } from '../domain/user-role';

export type AuthContext = {
  userId: string;
  role: UserRole;
  /** No MVP, teacherId = userId do professor autenticado */
  teacherId: string;
};

/**
 * Porta para autorização futura (Admin/Coordenador/Secretaria).
 * MVP: professor só acessa recursos próprios via teacherId nos repositórios.
 */
export interface AuthorizationPolicy {
  canAccessOwnResource(ctx: AuthContext, resourceTeacherId: string): boolean;
}

export class DefaultAuthorizationPolicy implements AuthorizationPolicy {
  canAccessOwnResource(ctx: AuthContext, resourceTeacherId: string): boolean {
    if (ctx.role === 'ADMIN') {
      return true;
    }

    return ctx.teacherId === resourceTeacherId;
  }
}
