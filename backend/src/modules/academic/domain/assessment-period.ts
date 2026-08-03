export type AssessmentPeriod = {
  id: string;
  teacherId: string;
  academicYearId: string;
  /** Extensão futura: override por turma (null = período do ano). */
  classId: string | null;
  name: string;
  sortOrder: number;
  startsOn: Date | null;
  endsOn: Date | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
