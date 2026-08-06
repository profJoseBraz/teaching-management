import '../../core/network/api_client.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_detail.dart';
import '../../domain/entities/activity_group.dart';
import '../../domain/entities/submission.dart';

Activity activityFromJson(Map<String, dynamic> json) {
  final disciplineIds = (json['disciplineIds'] as List? ?? const [])
      .cast<String>()
      .toList();
  // Compatibilidade com respostas antigas que ainda enviavam disciplineId singular.
  final legacyId = json['disciplineId'] as String?;
  if (disciplineIds.isEmpty && legacyId != null) {
    disciplineIds.add(legacyId);
  }

  return Activity(
    id: json['id'] as String,
    classId: json['classId'] as String,
    disciplineIds: disciplineIds,
    originLessonId: json['originLessonId'] as String?,
    assessmentPeriodId: json['assessmentPeriodId'] as String?,
    title: json['title'] as String,
    description: json['description'] as String?,
    tag: json['tag'] as String?,
    category: json['category'] as String? ?? 'ASSIGNMENT',
    mode: json['mode'] as String? ?? 'INDIVIDUAL',
    gradeMode: json['gradeMode'] as String? ?? 'INDIVIDUAL',
    maxScore: (json['maxScore'] as num?)?.toDouble() ?? 100,
    createdOn: DateTime.parse(json['createdOn'] as String),
    dueDate: DateTime.parse(json['dueDate'] as String),
    evaluated: json['evaluated'] as bool? ?? false,
    evaluatedAt: json['evaluatedAt'] != null ? DateTime.parse(json['evaluatedAt'] as String) : null,
  );
}

Submission submissionFromJson(Map<String, dynamic> json) => Submission(
      id: json['id'] as String,
      activityId: json['activityId'] as String,
      studentId: json['studentId'] as String,
      groupId: json['groupId'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      score: (json['score'] as num?)?.toDouble(),
      observations: json['observations'] as String?,
    );

ActivityGroup activityGroupFromJson(Map<String, dynamic> json) => ActivityGroup(
      id: json['id'] as String,
      activityId: json['activityId'] as String,
      name: json['name'] as String,
      studentIds: (json['studentIds'] as List? ?? []).cast<String>(),
    );

ActivityDetail _detailFromJson(Map<String, dynamic> json) {
  final summaryJson = json['summary'] as Map<String, dynamic>? ?? const {};
  return ActivityDetail(
    activity: activityFromJson(json['activity'] as Map<String, dynamic>),
    submissions: (json['submissions'] as List? ?? [])
        .map((e) => submissionFromJson(e as Map<String, dynamic>))
        .toList(),
    summary: ActivitySummary(
      total: summaryJson['total'] as int? ?? 0,
      pending: summaryJson['pending'] as int? ?? 0,
      submitted: summaryJson['submitted'] as int? ?? 0,
      graded: summaryJson['graded'] as int? ?? 0,
      averageScore: (summaryJson['averageScore'] as num?)?.toDouble(),
    ),
  );
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Fala com `/classes/{classId}/activities`, `/activities/{id}`,
/// `/activities/{id}/groups`, `/submissions/{id}` e correção em grupo.
class ActivitiesDatasource {
  ActivitiesDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Activity>> getActivities(
    String classId, {
    String? disciplineId,
    String? tag,
    String? assessmentPeriodId,
  }) async {
    final response = await _apiClient.get(
      '/classes/$classId/activities',
      query: {
        'disciplineId': disciplineId,
        'tag': tag,
        'assessmentPeriodId': assessmentPeriodId,
      },
    );
    return (response['data'] as List).map((e) => activityFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ActivityDetail> getActivity(String id) async {
    final response = await _apiClient.get('/activities/$id');
    return _detailFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Activity> createActivity(
    String classId, {
    String? originLessonId,
    /// Obrigatório sem [originLessonId]; com aula, a disciplina da aula é incluída automaticamente.
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
    final response = await _apiClient.post('/classes/$classId/activities', data: {
      if (originLessonId != null) 'originLessonId': originLessonId,
      if (disciplineIds.isNotEmpty) 'disciplineIds': disciplineIds,
      'assessmentPeriodId': assessmentPeriodId,
      'title': title,
      if (description != null) 'description': description,
      'tag': tag,
      'category': category,
      'mode': mode,
      'gradeMode': gradeMode,
      'maxScore': maxScore,
      'dueDate': _formatDate(dueDate),
    });
    return activityFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Activity> updateActivity(
    String id, {
    required String title,
    String? description,
    String? tag,
    required String category,
    required double maxScore,
    required DateTime dueDate,
    List<String>? disciplineIds,
    String? assessmentPeriodId,
  }) async {
    final response = await _apiClient.patch('/activities/$id', data: {
      'title': title,
      'description': description,
      'tag': tag,
      'category': category,
      'maxScore': maxScore,
      'dueDate': _formatDate(dueDate),
      if (disciplineIds != null) 'disciplineIds': disciplineIds,
      if (assessmentPeriodId != null) 'assessmentPeriodId': assessmentPeriodId,
    });
    return activityFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteActivity(String id) => _apiClient.delete('/activities/$id');

  Future<Activity> markEvaluated(String id) async {
    final response = await _apiClient.post('/activities/$id/mark-evaluated');
    return activityFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Activity> reopenEvaluation(String id) async {
    final response = await _apiClient.post('/activities/$id/reopen-evaluation');
    return activityFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<ActivityGroup>> createGroups(
    String activityId,
    List<({String name, List<String> studentIds})> groups,
  ) async {
    final response = await _apiClient.post('/activities/$activityId/groups', data: {
      'groups': groups.map((g) => {'name': g.name, 'studentIds': g.studentIds}).toList(),
    });
    return (response['data'] as List)
        .map((e) => activityGroupFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Submission>> getSubmissions(String activityId) async {
    final response = await _apiClient.get('/activities/$activityId/submissions');
    return (response['data'] as List).map((e) => submissionFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Submission> markSubmitted(String submissionId) async {
    final response = await _apiClient.patch('/submissions/$submissionId', data: {'status': 'SUBMITTED'});
    return submissionFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Submission> markPending(String submissionId) async {
    final response = await _apiClient.patch('/submissions/$submissionId', data: {'status': 'PENDING'});
    return submissionFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Submission> gradeSubmission(
    String submissionId, {
    required double score,
    String? observations,
  }) async {
    final response = await _apiClient.post('/submissions/$submissionId/grade', data: {
      'score': score,
      if (observations != null) 'observations': observations,
    });
    return submissionFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Submission>> gradeSubmissionsBulk(
    String activityId, {
    required List<String> submissionIds,
    required double score,
    String? observations,
  }) async {
    final response = await _apiClient.post(
      '/activities/$activityId/submissions/grade-bulk',
      data: {
        'submissionIds': submissionIds,
        'score': score,
        if (observations != null) 'observations': observations,
      },
    );
    return (response['data'] as List)
        .map((e) => submissionFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Submission>> gradeShared(
    String activityId,
    String groupId, {
    required double score,
    String? observations,
  }) async {
    final response = await _apiClient.post(
      '/activities/$activityId/groups/$groupId/grade-shared',
      data: {
        'score': score,
        if (observations != null) 'observations': observations,
      },
    );
    return (response['data'] as List).map((e) => submissionFromJson(e as Map<String, dynamic>)).toList();
  }
}
