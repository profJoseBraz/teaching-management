import '../entities/grade_composition.dart';

abstract interface class GradeCompositionsRepository {
  Future<GradeCompositionContext> getByContext({
    required String classId,
    required String disciplineId,
    required String assessmentPeriodId,
  });

  Future<GradeComposition> upsert({
    required String classId,
    required String disciplineId,
    required String assessmentPeriodId,
    required String evaluationModelId,
    required List<Map<String, dynamic>> groups,
  });

  Future<void> delete(String id);

  Future<GradeCompositionCalculation> calculate(String id);
}
