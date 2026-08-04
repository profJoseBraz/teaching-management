import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/activities_datasource.dart';
import '../../data/repositories/activities_repository_impl.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_detail.dart';
import '../../domain/entities/activity_group.dart';
import '../../domain/repositories/activities_repository.dart';
import 'session_providers.dart';

final activitiesDatasourceProvider = Provider<ActivitiesDatasource>(
  (ref) => ActivitiesDatasource(ref.watch(apiClientProvider)),
);

final activitiesRepositoryProvider = Provider<ActivitiesRepository>(
  (ref) => ActivitiesRepositoryImpl(ref.watch(activitiesDatasourceProvider)),
);

/// Filtro de listagem: turma obrigatória + disciplina/tag opcionais.
typedef ActivitiesQuery = ({String classId, String? disciplineId, String? tag});

final activitiesListProvider = FutureProvider.family<List<Activity>, ActivitiesQuery>((ref, query) {
  return ref
      .watch(activitiesRepositoryProvider)
      .getActivities(query.classId, disciplineId: query.disciplineId, tag: query.tag)
      .then((list) {
    list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return list;
  });
});

final activityDetailProvider = FutureProvider.family<ActivityDetail, String>((ref, activityId) {
  return ref.watch(activitiesRepositoryProvider).getActivity(activityId);
});

class ActivitiesActions {
  ActivitiesActions(this._ref);

  final Ref _ref;

  ActivitiesRepository get _repo => _ref.read(activitiesRepositoryProvider);

  Future<Activity> create(
    String classId, {
    String? originLessonId,
    String? disciplineId,
    String? assessmentPeriodId,
    required String title,
    String? description,
    String? tag,
    String category = 'ASSIGNMENT',
    String mode = 'INDIVIDUAL',
    String gradeMode = 'INDIVIDUAL',
    double maxScore = 100,
    required DateTime dueDate,
  }) async {
    final activity = await _repo.createActivity(
      classId,
      originLessonId: originLessonId,
      disciplineId: disciplineId,
      assessmentPeriodId: assessmentPeriodId,
      title: title,
      description: description,
      tag: tag,
      category: category,
      mode: mode,
      gradeMode: gradeMode,
      maxScore: maxScore,
      dueDate: dueDate,
    );
    _ref.invalidate(activitiesListProvider);
    return activity;
  }

  Future<void> update(
    String id, {
    required String classId,
    required String title,
    String? description,
    String? tag,
    required String category,
    required double maxScore,
    required DateTime dueDate,
  }) async {
    await _repo.updateActivity(
      id,
      title: title,
      description: description,
      tag: tag,
      category: category,
      maxScore: maxScore,
      dueDate: dueDate,
    );
    _ref.invalidate(activitiesListProvider);
    _ref.invalidate(activityDetailProvider(id));
  }

  Future<void> delete(String id, {required String classId}) async {
    await _repo.deleteActivity(id);
    _ref.invalidate(activitiesListProvider);
    _ref.invalidate(activityDetailProvider(id));
  }

  Future<List<ActivityGroup>> createGroups(
    String activityId,
    List<({String name, List<String> studentIds})> groups,
  ) async {
    final result = await _repo.createGroups(activityId, groups);
    _ref.invalidate(activityDetailProvider(activityId));
    return result;
  }

  Future<void> markSubmitted(String submissionId, {required String activityId}) async {
    await _repo.markSubmitted(submissionId);
    _ref.invalidate(activityDetailProvider(activityId));
  }

  Future<void> markPending(String submissionId, {required String activityId}) async {
    await _repo.markPending(submissionId);
    _ref.invalidate(activityDetailProvider(activityId));
  }

  Future<void> gradeSubmission(
    String submissionId, {
    required String activityId,
    required double score,
    String? observations,
  }) async {
    await _repo.gradeSubmission(submissionId, score: score, observations: observations);
    _ref.invalidate(activityDetailProvider(activityId));
  }

  Future<void> gradeShared(
    String activityId,
    String groupId, {
    required double score,
    String? observations,
  }) async {
    await _repo.gradeShared(activityId, groupId, score: score, observations: observations);
    _ref.invalidate(activityDetailProvider(activityId));
  }
}

final activitiesActionsProvider = Provider<ActivitiesActions>((ref) => ActivitiesActions(ref));
