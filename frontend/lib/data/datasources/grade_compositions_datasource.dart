import '../../core/network/api_client.dart';
import '../../domain/entities/grade_composition.dart';

GradeCompositionCalculationMethod _methodFromJson(String value) =>
    value == 'WEIGHTED_AVERAGE'
        ? GradeCompositionCalculationMethod.weightedAverage
        : GradeCompositionCalculationMethod.simpleAverage;

String methodToApi(GradeCompositionCalculationMethod method) =>
    method == GradeCompositionCalculationMethod.weightedAverage
        ? 'WEIGHTED_AVERAGE'
        : 'SIMPLE_AVERAGE';

GradeCompositionActivityLink _activityFromJson(Map<String, dynamic> json) =>
    GradeCompositionActivityLink(
      id: json['id'] as String,
      activityId: json['activityId'] as String,
      weight: json['weight'] == null ? null : (json['weight'] as num).toDouble(),
      activityTitle: json['activityTitle'] as String?,
      activityMaxScore:
          json['activityMaxScore'] == null ? null : (json['activityMaxScore'] as num).toDouble(),
    );

GradeCompositionGroup _groupFromJson(Map<String, dynamic> json) => GradeCompositionGroup(
      id: json['id'] as String,
      evaluationModelItemId: json['evaluationModelItemId'] as String,
      calculationMethod: _methodFromJson(json['calculationMethod'] as String),
      itemName: json['itemName'] as String? ?? '',
      itemMaxScore: (json['itemMaxScore'] as num?)?.toDouble() ?? 0,
      itemSortOrder: json['itemSortOrder'] as int? ?? 0,
      isRecovery: json['isRecovery'] as bool? ?? false,
      recoversItemId: json['recoversItemId'] as String?,
      activities: ((json['activities'] as List?) ?? const [])
          .map((e) => _activityFromJson(e as Map<String, dynamic>))
          .toList(),
    );

GradeComposition gradeCompositionFromJson(Map<String, dynamic> json) => GradeComposition(
      id: json['id'] as String,
      classId: json['classId'] as String,
      disciplineId: json['disciplineId'] as String,
      assessmentPeriodId: json['assessmentPeriodId'] as String,
      evaluationModelId: json['evaluationModelId'] as String,
      status: (json['status'] as String?) == 'FINALIZED'
          ? GradeCompositionStatus.finalized
          : GradeCompositionStatus.draft,
      finalizedAt:
          json['finalizedAt'] == null ? null : DateTime.parse(json['finalizedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      evaluationModelName: json['evaluationModelName'] as String?,
      groups: ((json['groups'] as List?) ?? const [])
          .map((e) => _groupFromJson(e as Map<String, dynamic>))
          .toList(),
    );

EligibleCompositionActivity _eligibleFromJson(Map<String, dynamic> json) =>
    EligibleCompositionActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      maxScore: (json['maxScore'] as num).toDouble(),
      tag: json['tag'] as String?,
      dueDate: DateTime.parse(json['dueDate'] as String),
    );

GradeCompositionCalculation _calculationFromJson(Map<String, dynamic> json) {
  final warnings = json['warnings'] as Map<String, dynamic>? ?? const {};
  final emptyGroups = ((warnings['emptyGroups'] as List?) ?? const [])
      .map((e) => (e as Map<String, dynamic>)['itemName'] as String? ?? '')
      .where((name) => name.isNotEmpty)
      .toList();

  return GradeCompositionCalculation(
    compositionId: json['compositionId'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    students: ((json['students'] as List?) ?? const []).map((row) {
      final map = row as Map<String, dynamic>;
      return GradeCompositionStudentRow(
        studentId: map['studentId'] as String,
        studentName: map['studentName'] as String,
        finalAverage: map['finalAverage'] == null
            ? null
            : (map['finalAverage'] as num).toDouble(),
        groups: ((map['groups'] as List?) ?? const []).map((g) {
          final group = g as Map<String, dynamic>;
          return GradeCompositionStudentGroupScore(
            evaluationModelItemId: group['evaluationModelItemId'] as String,
            itemName: group['itemName'] as String,
            itemMaxScore: (group['itemMaxScore'] as num).toDouble(),
            itemSortOrder: group['itemSortOrder'] as int? ?? 0,
            calculationMethod: _methodFromJson(group['calculationMethod'] as String),
            isRecovery: group['isRecovery'] as bool? ?? false,
            recoversItemId: group['recoversItemId'] as String?,
            convertedScore: group['convertedScore'] == null
                ? null
                : (group['convertedScore'] as num).toDouble(),
            consideredScore: group['consideredScore'] == null
                ? null
                : (group['consideredScore'] as num).toDouble(),
            activities: ((group['activities'] as List?) ?? const []).map((a) {
              final activity = a as Map<String, dynamic>;
              return GradeCompositionActivityBreakdown(
                activityId: activity['activityId'] as String,
                title: activity['title'] as String? ?? 'Atividade',
                description: activity['description'] as String?,
                maxScore: (activity['maxScore'] as num?)?.toDouble() ?? 0,
                score: activity['score'] == null
                    ? null
                    : (activity['score'] as num).toDouble(),
                weight: activity['weight'] == null
                    ? null
                    : (activity['weight'] as num).toDouble(),
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList(),
    emptyGroupNames: emptyGroups,
    ungroupedActivityCount: warnings['ungroupedActivityCount'] as int? ?? 0,
  );
}

class GradeCompositionsDatasource {
  GradeCompositionsDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<GradeCompositionContext> getByContext({
    required String classId,
    required String disciplineId,
    required String assessmentPeriodId,
  }) async {
    final response = await _apiClient.get(
      '/grade-compositions',
      query: {
        'classId': classId,
        'disciplineId': disciplineId,
        'assessmentPeriodId': assessmentPeriodId,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    final sync = data['sync'] as Map<String, dynamic>?;
    return GradeCompositionContext(
      composition: data['composition'] == null
          ? null
          : gradeCompositionFromJson(data['composition'] as Map<String, dynamic>),
      eligibleActivities: ((data['eligibleActivities'] as List?) ?? const [])
          .map((e) => _eligibleFromJson(e as Map<String, dynamic>))
          .toList(),
      groupsAdded: sync?['groupsAdded'] as int? ?? 0,
      groupsRemoved: sync?['groupsRemoved'] as int? ?? 0,
    );
  }

  Future<GradeComposition> upsert({
    required String classId,
    required String disciplineId,
    required String assessmentPeriodId,
    required String evaluationModelId,
    required List<Map<String, dynamic>> groups,
  }) async {
    final response = await _apiClient.put('/grade-compositions', data: {
      'classId': classId,
      'disciplineId': disciplineId,
      'assessmentPeriodId': assessmentPeriodId,
      'evaluationModelId': evaluationModelId,
      'groups': groups,
    });
    return gradeCompositionFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/grade-compositions/$id');
  }

  Future<GradeCompositionCalculation> calculate(String id) async {
    final response = await _apiClient.get('/grade-compositions/$id/calculate');
    return _calculationFromJson(response['data'] as Map<String, dynamic>);
  }
}
