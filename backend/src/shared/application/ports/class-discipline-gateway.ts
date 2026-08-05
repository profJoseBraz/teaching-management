/**
 * Porta compartilhada entre módulos (lessons, contents, activities) para validar
 * que uma disciplina está vinculada (ativamente) a uma turma antes de criar
 * recursos filhos por disciplina. Implementação Prisma vive em `shared/infra/prisma`.
 */
export interface ClassDisciplineGateway {
  isLinked(teacherId: string, classId: string, disciplineId: string): Promise<boolean>;
  /** Retorna true se todas as disciplinas informadas estão vinculadas ativamente à turma. */
  areAllLinked(teacherId: string, classId: string, disciplineIds: string[]): Promise<boolean>;
}
