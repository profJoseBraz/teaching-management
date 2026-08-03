import '../../domain/entities/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._datasource);

  final AttendanceDatasource _datasource;

  @override
  Future<AttendanceSheet> getSheet(String lessonId) => _datasource.getSheet(lessonId);

  @override
  Future<AttendanceSheet> saveAttendance(String lessonId, List<AttendanceSheetEntry> records) =>
      _datasource.saveAttendance(lessonId, records);

  @override
  Future<void> completeAttendance(String lessonId) => _datasource.completeAttendance(lessonId);
}
