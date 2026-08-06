export type Lesson = {
  id: string;
  teacherId: string;
  classId: string;
  disciplineId: string;
  assessmentPeriodId: string | null;
  date: Date;
  startTime: string;
  endTime: string;
  observations: string | null;
  attendanceCompleted: boolean;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};
