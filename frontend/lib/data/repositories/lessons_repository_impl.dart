import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lessons_repository.dart';
import '../datasources/lessons_datasource.dart';

class LessonsRepositoryImpl implements LessonsRepository {
  LessonsRepositoryImpl(this._datasource);

  final LessonsDatasource _datasource;

  @override
  Future<List<Lesson>> getLessons(
    String classId, {
    String? disciplineId,
    String? assessmentPeriodId,
  }) =>
      _datasource.getLessons(
        classId,
        disciplineId: disciplineId,
        assessmentPeriodId: assessmentPeriodId,
      );

  @override
  Future<Lesson> getLesson(String id) => _datasource.getLesson(id);

  @override
  Future<Lesson> createLesson(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? observations,
  }) =>
      _datasource.createLesson(
        classId,
        disciplineId: disciplineId,
        assessmentPeriodId: assessmentPeriodId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        observations: observations,
      );

  @override
  Future<({int totalCreated})> bulkCreateLessons(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
    required List<DateTime> dates,
    required String startTime,
    required String endTime,
    String? observations,
  }) =>
      _datasource.bulkCreateLessons(
        classId,
        disciplineId: disciplineId,
        assessmentPeriodId: assessmentPeriodId,
        dates: dates,
        startTime: startTime,
        endTime: endTime,
        observations: observations,
      );

  @override
  Future<Lesson> updateLesson(
    String id, {
    DateTime? date,
    String? startTime,
    String? endTime,
    String? observations,
    String? assessmentPeriodId,
  }) =>
      _datasource.updateLesson(
        id,
        date: date,
        startTime: startTime,
        endTime: endTime,
        observations: observations,
        assessmentPeriodId: assessmentPeriodId,
      );

  @override
  Future<void> deleteLesson(String id) => _datasource.deleteLesson(id);
}
