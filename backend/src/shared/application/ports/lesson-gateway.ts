export type LessonSummary = {
  id: string;
  teacherId: string;
  classId: string;
  disciplineId: string;
  attendanceCompleted: boolean;
};

/**
 * Porta compartilhada de leitura/escrita mínima sobre `Lesson`, usada por
 * módulos que não possuem a aula como agregado próprio (attendance, activities)
 * mas precisam validar vínculo/propriedade ou sinalizar `attendanceCompleted`.
 */
export interface LessonGateway {
  findById(lessonId: string, teacherId: string): Promise<LessonSummary | null>;
  markAttendanceCompleted(lessonId: string): Promise<void>;
}
