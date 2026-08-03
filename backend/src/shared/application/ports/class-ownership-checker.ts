/**
 * Porta compartilhada entre módulos (lessons, contents, activities) para validar
 * que uma turma (`classId`) pertence ao professor autenticado antes de criar
 * recursos filhos. Implementação Prisma vive em `shared/infra/prisma`.
 */
export interface ClassOwnershipChecker {
  isOwnedByTeacher(classId: string, teacherId: string): Promise<boolean>;
}
