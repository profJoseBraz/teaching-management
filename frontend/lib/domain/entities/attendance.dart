class AttendanceSheetEntry {
  const AttendanceSheetEntry({
    required this.studentId,
    required this.studentName,
    this.status,
    this.observations,
  });

  final String studentId;
  final String studentName;

  /// Um de: PRESENT, ABSENT, LATE ou null (aluno ainda sem registro).
  final String? status;
  final String? observations;

  AttendanceSheetEntry copyWith({String? status, String? observations}) => AttendanceSheetEntry(
        studentId: studentId,
        studentName: studentName,
        status: status ?? this.status,
        observations: observations ?? this.observations,
      );
}

class AttendanceSheet {
  const AttendanceSheet({
    required this.lessonId,
    required this.classId,
    required this.attendanceCompleted,
    required this.students,
  });

  final String lessonId;
  final String classId;
  final bool attendanceCompleted;
  final List<AttendanceSheetEntry> students;
}
