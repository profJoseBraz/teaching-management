/** Vínculo N:N entre turma e disciplinas ministradas nela (soft delete). */
export type ClassDiscipline = {
  id: string;
  teacherId: string;
  classId: string;
  disciplineId: string;
  createdAt: Date;
  deletedAt: Date | null;
};

/** Vínculo enriquecido com dados da disciplina, usado em listagens por turma. */
export type ClassDisciplineDetail = ClassDiscipline & {
  discipline: {
    id: string;
    name: string;
    description: string | null;
  };
};
