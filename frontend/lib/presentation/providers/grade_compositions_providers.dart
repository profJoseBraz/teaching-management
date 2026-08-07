import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/grade_compositions_datasource.dart';
import '../../data/repositories/grade_compositions_repository_impl.dart';
import '../../domain/entities/grade_composition.dart';
import '../../domain/repositories/grade_compositions_repository.dart';
import 'session_providers.dart';

final gradeCompositionsDatasourceProvider = Provider<GradeCompositionsDatasource>(
  (ref) => GradeCompositionsDatasource(ref.watch(apiClientProvider)),
);

final gradeCompositionsRepositoryProvider = Provider<GradeCompositionsRepository>(
  (ref) => GradeCompositionsRepositoryImpl(ref.watch(gradeCompositionsDatasourceProvider)),
);

typedef GradeCompositionQuery = ({
  String classId,
  String disciplineId,
  String assessmentPeriodId,
});

final gradeCompositionContextProvider =
    FutureProvider.family<GradeCompositionContext, GradeCompositionQuery>((ref, query) {
  return ref.watch(gradeCompositionsRepositoryProvider).getByContext(
        classId: query.classId,
        disciplineId: query.disciplineId,
        assessmentPeriodId: query.assessmentPeriodId,
      );
});

class GradeCompositionsActions {
  GradeCompositionsActions(this._ref);

  final Ref _ref;

  GradeCompositionsRepository get _repo => _ref.read(gradeCompositionsRepositoryProvider);

  Future<GradeComposition> upsert({
    required GradeCompositionQuery query,
    required String evaluationModelId,
    required List<Map<String, dynamic>> groups,
  }) async {
    final result = await _repo.upsert(
      classId: query.classId,
      disciplineId: query.disciplineId,
      assessmentPeriodId: query.assessmentPeriodId,
      evaluationModelId: evaluationModelId,
      groups: groups,
    );
    _ref.invalidate(gradeCompositionContextProvider(query));
    return result;
  }

  Future<GradeCompositionCalculation> calculate(String id) => _repo.calculate(id);
}

final gradeCompositionsActionsProvider = Provider<GradeCompositionsActions>(
  (ref) => GradeCompositionsActions(ref),
);
