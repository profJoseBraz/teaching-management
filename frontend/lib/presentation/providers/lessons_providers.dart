import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/lessons_datasource.dart';
import '../../data/repositories/lessons_repository_impl.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lessons_repository.dart';
import 'academic_providers.dart';
import 'session_providers.dart';

final lessonsDatasourceProvider = Provider<LessonsDatasource>(
  (ref) => LessonsDatasource(ref.watch(apiClientProvider)),
);

final lessonsRepositoryProvider = Provider<LessonsRepository>(
  (ref) => LessonsRepositoryImpl(ref.watch(lessonsDatasourceProvider)),
);

/// Filtro de listagem: turma + disciplina opcional + período opcional.
typedef LessonsQuery = ({String classId, String? disciplineId, String? assessmentPeriodId});

final lessonsListProvider = FutureProvider.family<List<Lesson>, LessonsQuery>((ref, query) {
  return ref
      .watch(lessonsRepositoryProvider)
      .getLessons(
        query.classId,
        disciplineId: query.disciplineId,
        assessmentPeriodId: query.assessmentPeriodId,
      )
      .then((lessons) {
    lessons.sort((a, b) => b.date.compareTo(a.date));
    return lessons;
  });
});

final lessonDetailProvider = FutureProvider.family<Lesson, String>((ref, id) {
  return ref.watch(lessonsRepositoryProvider).getLesson(id);
});

class LessonsActions {
  LessonsActions(this._ref);

  final Ref _ref;

  LessonsRepository get _repo => _ref.read(lessonsRepositoryProvider);

  Future<Lesson> create(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? observations,
  }) async {
    final lesson = await _repo.createLesson(
      classId,
      disciplineId: disciplineId,
      assessmentPeriodId: assessmentPeriodId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      observations: observations,
    );
    _ref.invalidate(lessonsListProvider);
    return lesson;
  }

  Future<({int totalCreated})> bulkCreate(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
    required List<DateTime> dates,
    required String startTime,
    required String endTime,
    String? observations,
  }) async {
    final result = await _repo.bulkCreateLessons(
      classId,
      disciplineId: disciplineId,
      assessmentPeriodId: assessmentPeriodId,
      dates: dates,
      startTime: startTime,
      endTime: endTime,
      observations: observations,
    );
    _ref.invalidate(lessonsListProvider);
    return result;
  }

  Future<void> update(
    String id, {
    required String classId,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? observations,
    String? assessmentPeriodId,
  }) async {
    await _repo.updateLesson(
      id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      observations: observations,
      assessmentPeriodId: assessmentPeriodId,
    );
    _ref.invalidate(lessonsListProvider);
    _ref.invalidate(lessonDetailProvider(id));
  }

  Future<void> delete(String id, {required String classId}) async {
    await _repo.deleteLesson(id);
    _ref.invalidate(lessonsListProvider);
  }
}

final lessonsActionsProvider = Provider<LessonsActions>((ref) => LessonsActions(ref));

/// Query padrão da turma usando o período global selecionado.
LessonsQuery lessonsQueryFor(WidgetRef ref, String classId, {String? disciplineId}) {
  return (
    classId: classId,
    disciplineId: disciplineId,
    assessmentPeriodId: ref.watch(effectiveAssessmentPeriodIdProvider),
  );
}
