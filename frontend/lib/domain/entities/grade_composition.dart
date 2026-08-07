enum GradeCompositionCalculationMethod { simpleAverage, weightedAverage }

enum GradeCompositionStatus { draft, finalized }

class GradeCompositionActivityLink {
  const GradeCompositionActivityLink({
    required this.id,
    required this.activityId,
    this.weight,
    this.activityTitle,
    this.activityMaxScore,
  });

  final String id;
  final String activityId;
  final double? weight;
  final String? activityTitle;
  final double? activityMaxScore;
}

class GradeCompositionGroup {
  const GradeCompositionGroup({
    required this.id,
    required this.evaluationModelItemId,
    required this.calculationMethod,
    required this.itemName,
    required this.itemMaxScore,
    required this.itemSortOrder,
    this.isRecovery = false,
    this.recoversItemId,
    required this.activities,
  });

  final String id;
  final String evaluationModelItemId;
  final GradeCompositionCalculationMethod calculationMethod;
  final String itemName;
  final double itemMaxScore;
  final int itemSortOrder;
  final bool isRecovery;
  final String? recoversItemId;
  final List<GradeCompositionActivityLink> activities;
}

class GradeComposition {
  const GradeComposition({
    required this.id,
    required this.classId,
    required this.disciplineId,
    required this.assessmentPeriodId,
    required this.evaluationModelId,
    required this.status,
    this.finalizedAt,
    required this.updatedAt,
    this.evaluationModelName,
    required this.groups,
  });

  final String id;
  final String classId;
  final String disciplineId;
  final String assessmentPeriodId;
  final String evaluationModelId;
  final GradeCompositionStatus status;
  final DateTime? finalizedAt;
  final DateTime updatedAt;
  final String? evaluationModelName;
  final List<GradeCompositionGroup> groups;
}

class EligibleCompositionActivity {
  const EligibleCompositionActivity({
    required this.id,
    required this.title,
    required this.maxScore,
    this.tag,
    required this.dueDate,
  });

  final String id;
  final String title;
  final double maxScore;
  final String? tag;
  final DateTime dueDate;
}

class GradeCompositionContext {
  const GradeCompositionContext({
    this.composition,
    required this.eligibleActivities,
    this.groupsAdded = 0,
    this.groupsRemoved = 0,
  });

  final GradeComposition? composition;
  final List<EligibleCompositionActivity> eligibleActivities;
  final int groupsAdded;
  final int groupsRemoved;
}

class GradeCompositionActivityBreakdown {
  const GradeCompositionActivityBreakdown({
    required this.activityId,
    required this.title,
    this.description,
    required this.maxScore,
    this.score,
    this.weight,
  });

  final String activityId;
  final String title;
  final String? description;
  final double maxScore;
  final double? score;
  final double? weight;
}

class GradeCompositionStudentGroupScore {
  const GradeCompositionStudentGroupScore({
    required this.evaluationModelItemId,
    required this.itemName,
    required this.itemMaxScore,
    required this.itemSortOrder,
    required this.calculationMethod,
    this.isRecovery = false,
    this.recoversItemId,
    this.convertedScore,
    this.consideredScore,
    this.activities = const [],
  });

  final String evaluationModelItemId;
  final String itemName;
  final double itemMaxScore;
  final int itemSortOrder;
  final GradeCompositionCalculationMethod calculationMethod;
  final bool isRecovery;
  final String? recoversItemId;
  /// Nota bruta do grupo.
  final double? convertedScore;
  /// Nota considerada (regular = max com recuperação).
  final double? consideredScore;
  final List<GradeCompositionActivityBreakdown> activities;
}

class GradeCompositionStudentRow {
  const GradeCompositionStudentRow({
    required this.studentId,
    required this.studentName,
    required this.groups,
    this.finalAverage,
  });

  final String studentId;
  final String studentName;
  final List<GradeCompositionStudentGroupScore> groups;
  /// Média final 0–100 dos itens regulares (máxima em todos → 100).
  final double? finalAverage;
}

class GradeCompositionCalculation {
  const GradeCompositionCalculation({
    required this.compositionId,
    required this.updatedAt,
    required this.students,
    required this.emptyGroupNames,
    required this.ungroupedActivityCount,
  });

  final String compositionId;
  final DateTime updatedAt;
  final List<GradeCompositionStudentRow> students;
  final List<String> emptyGroupNames;
  final int ungroupedActivityCount;
}
