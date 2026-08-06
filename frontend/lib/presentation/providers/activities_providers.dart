import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/activities_datasource.dart';
import '../../data/repositories/activities_repository_impl.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_detail.dart';
import '../../domain/entities/activity_group.dart';
import '../../domain/entities/submission.dart';
import '../../domain/repositories/activities_repository.dart';
import 'academic_providers.dart';
import 'session_providers.dart';

final activitiesDatasourceProvider = Provider<ActivitiesDatasource>(
  (ref) => ActivitiesDatasource(ref.watch(apiClientProvider)),
);

final activitiesRepositoryProvider = Provider<ActivitiesRepository>(
  (ref) => ActivitiesRepositoryImpl(ref.watch(activitiesDatasourceProvider)),
);

/// Filtro de listagem: turma + disciplina/tag/período opcionais.
typedef ActivitiesQuery = ({
  String classId,
  String? disciplineId,
  String? tag,
  String? assessmentPeriodId,
});

final activitiesListProvider = FutureProvider.family<List<Activity>, ActivitiesQuery>((ref, query) {
  return ref
      .watch(activitiesRepositoryProvider)
      .getActivities(
        query.classId,
        disciplineId: query.disciplineId,
        tag: query.tag,
        assessmentPeriodId: query.assessmentPeriodId,
      )
      .then((list) {
    list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return list;
  });
});

/// Detalhe com AsyncNotifier para aplicar PATCH de entrega/nota sem novo GET.
class ActivityDetailNotifier extends FamilyAsyncNotifier<ActivityDetail, String> {
  @override
  Future<ActivityDetail> build(String arg) {
    return ref.read(activitiesRepositoryProvider).getActivity(arg);
  }

  void applySubmissions(Iterable<Submission> updates) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.withUpdatedSubmissions(updates));
  }
}

final activityDetailProvider =
    AsyncNotifierProvider.family<ActivityDetailNotifier, ActivityDetail, String>(
  ActivityDetailNotifier.new,
);

class ActivitiesActions {
  ActivitiesActions(this._ref);

  final Ref _ref;

  ActivitiesRepository get _repo => _ref.read(activitiesRepositoryProvider);

  void _patchSubmissions(String activityId, Iterable<Submission> updates) {
    final current = _ref.read(activityDetailProvider(activityId)).valueOrNull;
    if (current == null) {
      _ref.invalidate(activityDetailProvider(activityId));
      return;
    }
    _ref.read(activityDetailProvider(activityId).notifier).applySubmissions(updates);
  }

  Future<Activity> create(
    String classId, {
    String? originLessonId,
    List<String> disciplineIds = const [],
    required String assessmentPeriodId,
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
      disciplineIds: disciplineIds,
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
    List<String>? disciplineIds,
    String? assessmentPeriodId,
  }) async {
    await _repo.updateActivity(
      id,
      title: title,
      description: description,
      tag: tag,
      category: category,
      maxScore: maxScore,
      dueDate: dueDate,
      disciplineIds: disciplineIds,
      assessmentPeriodId: assessmentPeriodId,
    );
    _ref.invalidate(activitiesListProvider);
    _ref.invalidate(activityDetailProvider(id));
  }

  Future<void> delete(String id, {required String classId}) async {
    await _repo.deleteActivity(id);
    _ref.invalidate(activitiesListProvider);
    _ref.invalidate(activityDetailProvider(id));
  }

  Future<void> markEvaluated(String id, {required String classId}) async {
    await _repo.markEvaluated(id);
    _ref.invalidate(activitiesListProvider);
    _ref.invalidate(activityDetailProvider(id));
  }

  Future<void> reopenEvaluation(String id, {required String classId}) async {
    await _repo.reopenEvaluation(id);
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
    final updated = await _repo.markSubmitted(submissionId);
    _patchSubmissions(activityId, [updated]);
  }

  Future<void> markPending(String submissionId, {required String activityId}) async {
    final updated = await _repo.markPending(submissionId);
    _patchSubmissions(activityId, [updated]);
  }

  Future<void> gradeSubmission(
    String submissionId, {
    required String activityId,
    required double score,
    String? observations,
  }) async {
    final updated = await _repo.gradeSubmission(
      submissionId,
      score: score,
      observations: observations,
    );
    _patchSubmissions(activityId, [updated]);
  }

  Future<void> gradeSubmissionsBulk(
    String activityId, {
    required List<String> submissionIds,
    required double score,
    String? observations,
  }) async {
    final updated = await _repo.gradeSubmissionsBulk(
      activityId,
      submissionIds: submissionIds,
      score: score,
      observations: observations,
    );
    _patchSubmissions(activityId, updated);
  }

  Future<void> gradeShared(
    String activityId,
    String groupId, {
    required double score,
    String? observations,
  }) async {
    final updated = await _repo.gradeShared(
      activityId,
      groupId,
      score: score,
      observations: observations,
    );
    _patchSubmissions(activityId, updated);
  }
}

final activitiesActionsProvider = Provider<ActivitiesActions>((ref) => ActivitiesActions(ref));

ActivitiesQuery activitiesQueryFor(WidgetRef ref, String classId, {String? disciplineId, String? tag}) {
  return (
    classId: classId,
    disciplineId: disciplineId,
    tag: tag,
    assessmentPeriodId: ref.watch(effectiveAssessmentPeriodIdProvider),
  );
}
