import '../../core/network/api_client.dart';
import '../../domain/entities/attendance.dart';

AttendanceSheetEntry _entryFromJson(Map<String, dynamic> json) => AttendanceSheetEntry(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      status: json['status'] as String?,
      observations: json['observations'] as String?,
    );

AttendanceSheet attendanceSheetFromJson(Map<String, dynamic> json) => AttendanceSheet(
      lessonId: json['lessonId'] as String,
      classId: json['classId'] as String,
      attendanceCompleted: json['attendanceCompleted'] as bool? ?? false,
      students: (json['students'] as List).map((e) => _entryFromJson(e as Map<String, dynamic>)).toList(),
    );

/// Fala com `/lessons/{lessonId}/attendance` e `/attendance/complete`.
class AttendanceDatasource {
  AttendanceDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<AttendanceSheet> getSheet(String lessonId) async {
    final response = await _apiClient.get('/lessons/$lessonId/attendance');
    return attendanceSheetFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AttendanceSheet> saveAttendance(
    String lessonId,
    List<AttendanceSheetEntry> records,
  ) async {
    final response = await _apiClient.put('/lessons/$lessonId/attendance', data: {
      'records': records
          .where((e) => e.status != null)
          .map((e) => {
                'studentId': e.studentId,
                'status': e.status,
                if (e.observations != null) 'observations': e.observations,
              })
          .toList(),
    });
    final data = response['data'];
    if (data is Map<String, dynamic> && data.containsKey('students')) {
      return attendanceSheetFromJson(data);
    }
    // Alguns backends retornam apenas um ack; recarregamos a folha atual.
    return getSheet(lessonId);
  }

  Future<void> completeAttendance(String lessonId) =>
      _apiClient.post('/lessons/$lessonId/attendance/complete');
}
