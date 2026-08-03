export const CLASS_SHIFTS = ['MORNING', 'AFTERNOON', 'EVENING', 'NIGHT'] as const;
export type ClassShift = (typeof CLASS_SHIFTS)[number];

export const CLASS_STATUSES = ['ACTIVE', 'ARCHIVED'] as const;
export type ClassStatus = (typeof CLASS_STATUSES)[number];

export type Class = {
  id: string;
  teacherId: string;
  academicYearId: string;
  courseId: string;
  name: string;
  shift: ClassShift | null;
  status: ClassStatus;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

/**
 * Turma enriquecida com as disciplinas atualmente vinculadas (via `ClassDiscipline`).
 * Usada nas respostas de Create/Get/List/Update/Archive para evitar uma chamada extra do frontend.
 */
export type ClassWithDisciplines = Class & {
  disciplineIds: string[];
  disciplines: { id: string; name: string }[];
};
