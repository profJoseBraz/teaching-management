import '../entities/activity.dart';
import '../entities/activity_detail.dart';
import '../entities/activity_group.dart';
import '../entities/submission.dart';

abstract interface class ActivitiesRepository {
  Future<List<Activity>> getActivities(String classId, {String? disciplineId});
  Future<ActivityDetail> getActivity(String id);
  Future<Activity> createActivity(
    String classId, {
    required String originLessonId,
    String? disciplineId,
    String? assessmentPeriodId,
    required String title,
    String? description,
    String category = 'ASSIGNMENT',
    String mode = 'INDIVIDUAL',
    String gradeMode = 'INDIVIDUAL',
    double maxScore = 100,
    required DateTime dueDate,
  });
  Future<Activity> updateActivity(
    String id, {
    String? title,
    String? description,
    String? category,
    double? maxScore,
    DateTime? dueDate,
  });

  Future<List<ActivityGroup>> createGroups(
    String activityId,
    List<({String name, List<String> studentIds})> groups,
  );

  Future<List<Submission>> getSubmissions(String activityId);
  Future<Submission> markSubmitted(String submissionId);
  Future<Submission> gradeSubmission(String submissionId, {required double score, String? observations});
  Future<List<Submission>> gradeShared(
    String activityId,
    String groupId, {
    required double score,
    String? observations,
  });
}
