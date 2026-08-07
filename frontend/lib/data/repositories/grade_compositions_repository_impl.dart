import '../../domain/entities/grade_composition.dart';
import '../../domain/repositories/grade_compositions_repository.dart';
import '../datasources/grade_compositions_datasource.dart';

class GradeCompositionsRepositoryImpl implements GradeCompositionsRepository {
  GradeCompositionsRepositoryImpl(this._datasource);

  final GradeCompositionsDatasource _datasource;

  @override
  Future<GradeCompositionContext> getByContext({
    required String classId,
    required String disciplineId,
    required String assessmentPeriodId,
  }) =>
      _datasource.getByContext(
        classId: classId,
        disciplineId: disciplineId,
        assessmentPeriodId: assessmentPeriodId,
      );

  @override
  Future<GradeComposition> upsert({
    required String classId,
    required String disciplineId,
    required String assessmentPeriodId,
    required String evaluationModelId,
    required List<Map<String, dynamic>> groups,
  }) =>
      _datasource.upsert(
        classId: classId,
        disciplineId: disciplineId,
        assessmentPeriodId: assessmentPeriodId,
        evaluationModelId: evaluationModelId,
        groups: groups,
      );

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<GradeCompositionCalculation> calculate(String id) => _datasource.calculate(id);
}
