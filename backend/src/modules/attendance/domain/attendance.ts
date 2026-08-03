export type AttendanceStatus = 'PRESENT' | 'ABSENT' | 'LATE';

export type AttendanceRecord = {
  id: string;
  teacherId: string;
  lessonId: string;
  studentId: string;
  status: AttendanceStatus;
  observations: string | null;
  createdAt: Date;
  updatedAt: Date;
};

export type AttendanceSheetEntry = {
  studentId: string;
  studentName: string;
  status: AttendanceStatus | null;
  observations: string | null;
};

export type AttendanceSheet = {
  lessonId: string;
  classId: string;
  attendanceCompleted: boolean;
  students: AttendanceSheetEntry[];
};
