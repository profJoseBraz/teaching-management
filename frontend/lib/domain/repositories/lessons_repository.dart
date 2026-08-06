import '../entities/lesson.dart';

abstract interface class LessonsRepository {
  Future<List<Lesson>> getLessons(String classId, {String? disciplineId, String? assessmentPeriodId});
  Future<Lesson> getLesson(String id);
  Future<Lesson> createLesson(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? observations,
  });
  Future<({int totalCreated})> bulkCreateLessons(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
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
    String? assessmentPeriodId,
  });
  Future<void> deleteLesson(String id);
}
