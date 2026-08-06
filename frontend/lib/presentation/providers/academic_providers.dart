import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/academic_datasource.dart';
import '../../data/repositories/academic_repository_impl.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/assessment_period.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_discipline.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/repositories/academic_repository.dart';
import 'session_providers.dart';

final academicDatasourceProvider = Provider<AcademicDatasource>(
  (ref) => AcademicDatasource(ref.watch(apiClientProvider)),
);

final academicRepositoryProvider = Provider<AcademicRepository>(
  (ref) => AcademicRepositoryImpl(ref.watch(academicDatasourceProvider)),
);

/// Lista de anos letivos do professor autenticado.
final academicYearsProvider = FutureProvider<List<AcademicYear>>((ref) async {
  final repo = ref.watch(academicRepositoryProvider);
  final years = await repo.getAcademicYears();
  years.sort((a, b) => b.year.compareTo(a.year));
  return years;
});

const _selectedYearPrefsKey = 'gd_selected_academic_year_id';

/// Ano letivo selecionado manualmente pelo usuário no seletor global.
/// `null` significa "usar o ano marcado como atual (ou o mais recente)".
class SelectedYearNotifier extends StateNotifier<String?> {
  SelectedYearNotifier(this._ref) : super(_ref.read(sharedPreferencesProvider).getString(_selectedYearPrefsKey));

  final Ref _ref;

  void select(String? id) {
    state = id;
    final prefs = _ref.read(sharedPreferencesProvider);
    if (id == null) {
      prefs.remove(_selectedYearPrefsKey);
    } else {
      prefs.setString(_selectedYearPrefsKey, id);
    }
  }
}

final selectedAcademicYearIdProvider = StateNotifierProvider<SelectedYearNotifier, String?>(
  (ref) => SelectedYearNotifier(ref),
);

/// Ano letivo efetivamente em uso pelas telas: o selecionado manualmente,
/// ou o marcado como `isCurrent`, ou o mais recente disponível.
final effectiveAcademicYearProvider = Provider<AcademicYear?>((ref) {
  final years = ref.watch(academicYearsProvider).valueOrNull;
  if (years == null || years.isEmpty) return null;
  final manualId = ref.watch(selectedAcademicYearIdProvider);
  if (manualId != null) {
    for (final year in years) {
      if (year.id == manualId) return year;
    }
  }
  for (final year in years) {
    if (year.isCurrent) return year;
  }
  return years.first;
});

final effectiveAcademicYearIdProvider = Provider<String?>((ref) {
  return ref.watch(effectiveAcademicYearProvider)?.id;
});

final coursesProvider = FutureProvider<List<Course>>((ref) {
  return ref.watch(academicRepositoryProvider).getCourses();
});

final disciplinesProvider = FutureProvider<List<Discipline>>((ref) {
  return ref.watch(academicRepositoryProvider).getDisciplines();
});

final assessmentPeriodsProvider = FutureProvider.family<List<AssessmentPeriod>, String>((ref, academicYearId) {
  return ref.watch(academicRepositoryProvider).getAssessmentPeriods(academicYearId);
});

const _selectedPeriodPrefsKey = 'gd_selected_assessment_period_id';

/// Período avaliativo selecionado manualmente (`null` = usar o primeiro do ano).
class SelectedPeriodNotifier extends StateNotifier<String?> {
  SelectedPeriodNotifier(this._ref)
      : super(_ref.read(sharedPreferencesProvider).getString(_selectedPeriodPrefsKey));

  final Ref _ref;

  void select(String? id) {
    state = id;
    final prefs = _ref.read(sharedPreferencesProvider);
    if (id == null) {
      prefs.remove(_selectedPeriodPrefsKey);
    } else {
      prefs.setString(_selectedPeriodPrefsKey, id);
    }
  }
}

final selectedAssessmentPeriodIdProvider =
    StateNotifierProvider<SelectedPeriodNotifier, String?>((ref) => SelectedPeriodNotifier(ref));

/// Períodos do ano letivo efetivo (ordenados).
final effectiveYearPeriodsProvider = Provider<AsyncValue<List<AssessmentPeriod>>>((ref) {
  final yearId = ref.watch(effectiveAcademicYearIdProvider);
  if (yearId == null) return const AsyncData([]);
  return ref.watch(assessmentPeriodsProvider(yearId));
});

/// Período efetivo: seleção manual (se ainda existir no ano) ou o de menor `sortOrder`.
final effectiveAssessmentPeriodProvider = Provider<AssessmentPeriod?>((ref) {
  final periodsAsync = ref.watch(effectiveYearPeriodsProvider);
  final periods = periodsAsync.valueOrNull;
  if (periods == null || periods.isEmpty) return null;

  final sorted = [...periods]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final manualId = ref.watch(selectedAssessmentPeriodIdProvider);
  if (manualId != null) {
    for (final period in sorted) {
      if (period.id == manualId) return period;
    }
  }
  return sorted.first;
});

final effectiveAssessmentPeriodIdProvider = Provider<String?>((ref) {
  return ref.watch(effectiveAssessmentPeriodProvider)?.id;
});

/// Ao trocar o ano letivo, limpa a seleção de período se ela não pertencer ao novo ano.
final academicYearPeriodSyncProvider = Provider<void>((ref) {
  ref.listen(effectiveAcademicYearIdProvider, (previous, next) {
    if (previous == next) return;
    final selected = ref.read(selectedAssessmentPeriodIdProvider);
    if (selected == null || next == null) return;
    // Invalida/espera a lista do novo ano e limpa se o id antigo não existir.
    ref.read(assessmentPeriodsProvider(next).future).then((periods) {
      final stillValid = periods.any((p) => p.id == selected);
      if (!stillValid) {
        ref.read(selectedAssessmentPeriodIdProvider.notifier).select(null);
      }
    });
  });
});

/// Ações de escrita da estrutura acadêmica (anos, cursos, disciplinas,
/// vínculos e períodos avaliativos). Usada pela tela de Configurações.
class AcademicActions {
  AcademicActions(this._ref);

  final Ref _ref;

  AcademicRepository get _repo => _ref.read(academicRepositoryProvider);

  Future<void> createAcademicYear({required int year, String? label, DateTime? startsOn, DateTime? endsOn}) async {
    await _repo.createAcademicYear(year: year, label: label, startsOn: startsOn, endsOn: endsOn);
    _ref.invalidate(academicYearsProvider);
  }

  Future<void> updateAcademicYear(String id, {String? label, DateTime? startsOn, DateTime? endsOn}) async {
    await _repo.updateAcademicYear(id, label: label, startsOn: startsOn, endsOn: endsOn);
    _ref.invalidate(academicYearsProvider);
  }

  Future<void> setCurrentAcademicYear(String id) async {
    await _repo.setCurrentAcademicYear(id);
    _ref.invalidate(academicYearsProvider);
  }

  Future<void> createCourse({required String name, String? description}) async {
    await _repo.createCourse(name: name, description: description);
    _ref.invalidate(coursesProvider);
  }

  Future<void> updateCourse(String id, {required String name, String? description}) async {
    await _repo.updateCourse(id, name: name, description: description);
    _ref.invalidate(coursesProvider);
  }

  Future<void> deleteCourse(String id) async {
    await _repo.deleteCourse(id);
    _ref.invalidate(coursesProvider);
  }

  Future<void> createDiscipline({required String name, String? description}) async {
    await _repo.createDiscipline(name: name, description: description);
    _ref.invalidate(disciplinesProvider);
  }

  Future<void> updateDiscipline(String id, {String? name, String? description}) async {
    await _repo.updateDiscipline(id, name: name, description: description);
    _ref.invalidate(disciplinesProvider);
  }

  Future<void> deleteDiscipline(String id) async {
    await _repo.deleteDiscipline(id);
    _ref.invalidate(disciplinesProvider);
  }

  Future<void> linkDisciplineToCourse(String courseId, String disciplineId) async {
    await _repo.linkDisciplineToCourse(courseId, disciplineId);
    _ref.invalidate(courseDisciplinesProvider(courseId));
  }

  Future<void> unlinkDisciplineFromCourse(String courseId, String disciplineId) async {
    await _repo.unlinkDisciplineFromCourse(courseId, disciplineId);
    _ref.invalidate(courseDisciplinesProvider(courseId));
  }

  Future<void> createAssessmentPeriod({
    required String academicYearId,
    String? classId,
    required String name,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    await _repo.createAssessmentPeriod(
      academicYearId: academicYearId,
      classId: classId,
      name: name,
      startsOn: startsOn,
      endsOn: endsOn,
    );
    _ref.invalidate(assessmentPeriodsProvider(academicYearId));
  }

  Future<void> updateAssessmentPeriod(
    String id, {
    required String academicYearId,
    String? name,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    await _repo.updateAssessmentPeriod(id, name: name, startsOn: startsOn, endsOn: endsOn);
    _ref.invalidate(assessmentPeriodsProvider(academicYearId));
  }

  Future<void> reorderAssessmentPeriods({
    required String academicYearId,
    required List<String> orderedIds,
  }) async {
    await _repo.reorderAssessmentPeriods(academicYearId: academicYearId, orderedIds: orderedIds);
    _ref.invalidate(assessmentPeriodsProvider(academicYearId));
  }
}

final academicActionsProvider = Provider<AcademicActions>((ref) => AcademicActions(ref));

final courseDisciplinesProvider = FutureProvider.family<List<CourseDiscipline>, String>((ref, courseId) {
  return ref.watch(academicRepositoryProvider).getCourseDisciplines(courseId);
});
