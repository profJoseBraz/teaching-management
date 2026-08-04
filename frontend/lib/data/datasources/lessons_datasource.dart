import '../../core/network/api_client.dart';
import '../../domain/entities/lesson.dart';

Lesson lessonFromJson(Map<String, dynamic> json) => Lesson(
      id: json['id'] as String,
      classId: json['classId'] as String,
      disciplineId: json['disciplineId'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      observations: json['observations'] as String?,
      attendanceCompleted: json['attendanceCompleted'] as bool? ?? false,
    );

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Fala com `/classes/{classId}/lessons` e `/lessons/{id}`.
class LessonsDatasource {
  LessonsDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Lesson>> getLessons(String classId, {String? disciplineId}) async {
    final response = await _apiClient.get(
      '/classes/$classId/lessons',
      query: {'disciplineId': disciplineId},
    );
    return (response['data'] as List).map((e) => lessonFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Lesson> getLesson(String id) async {
    final response = await _apiClient.get('/lessons/$id');
    return lessonFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Lesson> createLesson(
    String classId, {
    required String disciplineId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? observations,
  }) async {
    final response = await _apiClient.post('/classes/$classId/lessons', data: {
      'disciplineId': disciplineId,
      'date': _formatDate(date),
      'startTime': startTime,
      'endTime': endTime,
      if (observations != null) 'observations': observations,
    });
    return lessonFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<({int totalCreated})> bulkCreateLessons(
    String classId, {
    required String disciplineId,
    required List<DateTime> dates,
    required String startTime,
    required String endTime,
    String? observations,
  }) async {
    final response = await _apiClient.post('/classes/$classId/lessons/bulk', data: {
      'disciplineId': disciplineId,
      'dates': dates.map(_formatDate).toList(),
      'startTime': startTime,
      'endTime': endTime,
      if (observations != null) 'observations': observations,
    });
    final data = response['data'] as Map<String, dynamic>;
    return (totalCreated: data['totalCreated'] as int? ?? 0);
  }

  Future<Lesson> updateLesson(
    String id, {
    DateTime? date,
    String? startTime,
    String? endTime,
    String? observations,
  }) async {
    final response = await _apiClient.patch('/lessons/$id', data: {
      if (date != null) 'date': _formatDate(date),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (observations != null) 'observations': observations,
    });
    return lessonFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteLesson(String id) => _apiClient.delete('/lessons/$id');
}
