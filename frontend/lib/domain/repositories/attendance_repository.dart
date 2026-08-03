import '../entities/attendance.dart';

abstract interface class AttendanceRepository {
  Future<AttendanceSheet> getSheet(String lessonId);
  Future<AttendanceSheet> saveAttendance(
    String lessonId,
    List<AttendanceSheetEntry> records,
  );
  Future<void> completeAttendance(String lessonId);
}
