/**
 * Valida que um período avaliativo pode ser usado em recursos de uma turma
 * (mesmo professor e mesmo ano letivo da turma).
 */
export interface AssessmentPeriodGateway {
  assertUsableForClass(input: {
    teacherId: string;
    classId: string;
    assessmentPeriodId: string;
  }): Promise<void>;
}
