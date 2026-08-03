export type AcademicYear = {
  id: string;
  teacherId: string;
  year: number;
  label: string | null;
  isCurrent: boolean;
  startsOn: Date | null;
  endsOn: Date | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
