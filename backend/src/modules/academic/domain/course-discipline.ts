export type CourseDiscipline = {
  id: string;
  teacherId: string;
  courseId: string;
  disciplineId: string;
  createdAt: Date;
  deletedAt: Date | null;
};

/** Vínculo enriquecido com dados da disciplina, usado em listagens por curso. */
export type CourseDisciplineDetail = CourseDiscipline & {
  discipline: {
    id: string;
    name: string;
    description: string | null;
  };
};
