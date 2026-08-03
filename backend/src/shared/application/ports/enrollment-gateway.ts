export type ActiveEnrollmentStudent = {
  studentId: string;
  studentName: string;
};

/**
 * Porta compartilhada de leitura de matrículas ativas, usada por attendance
 * (folha de chamada) e activities (geração de submissions e formação de grupos).
 */
export interface EnrollmentGateway {
  listActiveStudents(classId: string): Promise<ActiveEnrollmentStudent[]>;
  areAllStudentsActiveInClass(classId: string, studentIds: string[]): Promise<boolean>;
}
