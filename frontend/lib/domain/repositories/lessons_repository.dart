import '../entities/lesson.dart';

abstract interface class LessonsRepository {
  Future<List<Lesson>> getLessons(String classId, {String? disciplineId});
  Future<Lesson> getLesson(String id);
  Future<Lesson> createLesson(
    String classId, {
    required String disciplineId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? observations,
  });
  Future<({int totalCreated})> bulkCreateLessons(
    String classId, {
    required String disciplineId,
    required List<DateTime> dates,
    required String startTime,
    required String endTime,
    String? observations,
  });
  Future<Lesson> updateLesson(
    String id, {
    DateTime? date,
    String? startTime,
    String? endTime,
    String? observations,
  });
  Future<void> deleteLesson(String id);
}
