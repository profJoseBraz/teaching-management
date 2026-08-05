import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_detail.dart';
import '../../domain/entities/activity_group.dart';
import '../../domain/entities/submission.dart';
import '../../domain/repositories/activities_repository.dart';
import '../datasources/activities_datasource.dart';

class ActivitiesRepositoryImpl implements ActivitiesRepository {
  ActivitiesRepositoryImpl(this._datasource);

  final ActivitiesDatasource _datasource;

  @override
  Future<List<Activity>> getActivities(String classId, {String? disciplineId, String? tag}) =>
      _datasource.getActivities(classId, disciplineId: disciplineId, tag: tag);

  @override
  Future<ActivityDetail> getActivity(String id) => _datasource.getActivity(id);

  @override
  Future<Activity> createActivity(
    String classId, {
    String? originLessonId,
    List<String> disciplineIds = const [],
    String? assessmentPeriodId,
    required String title,
    String? description,
    String? tag,
    String category = 'ASSIGNMENT',
    String mode = 'INDIVIDUAL',
    String gradeMode = 'INDIVIDUAL',
    double maxScore = 100,
    required DateTime dueDate,
  }) =>
      _datasource.createActivity(
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

  @override
  Future<Activity> updateActivity(
    String id, {
    required String title,
    String? description,
    String? tag,
    required String category,
    required double maxScore,
    required DateTime dueDate,
    List<String>? disciplineIds,
  }) =>
      _datasource.updateActivity(
        id,
        title: title,
        description: description,
        tag: tag,
        category: category,
        maxScore: maxScore,
        dueDate: dueDate,
        disciplineIds: disciplineIds,
      );

  @override
  Future<void> deleteActivity(String id) => _datasource.deleteActivity(id);

  @override
  Future<List<ActivityGroup>> createGroups(
    String activityId,
    List<({String name, List<String> studentIds})> groups,
  ) =>
      _datasource.createGroups(activityId, groups);

  @override
  Future<List<Submission>> getSubmissions(String activityId) => _datasource.getSubmissions(activityId);

  @override
  Future<Submission> markSubmitted(String submissionId) => _datasource.markSubmitted(submissionId);

  @override
  Future<Submission> markPending(String submissionId) => _datasource.markPending(submissionId);

  @override
  Future<Submission> gradeSubmission(String submissionId, {required double score, String? observations}) =>
      _datasource.gradeSubmission(submissionId, score: score, observations: observations);

  @override
  Future<List<Submission>> gradeSubmissionsBulk(
    String activityId, {
    required List<String> submissionIds,
    required double score,
    String? observations,
  }) =>
      _datasource.gradeSubmissionsBulk(
        activityId,
        submissionIds: submissionIds,
        score: score,
        observations: observations,
      );

  @override
  Future<List<Submission>> gradeShared(
    String activityId,
    String groupId, {
    required double score,
    String? observations,
  }) =>
      _datasource.gradeShared(activityId, groupId, score: score, observations: observations);
}
