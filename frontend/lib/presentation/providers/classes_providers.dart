import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/classes_datasource.dart';
import '../../data/repositories/classes_repository_impl.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/enrollment.dart';
import '../../domain/entities/school_class.dart';
import '../../domain/repositories/classes_repository.dart';
import 'academic_providers.dart';
import 'session_providers.dart';

final classesDatasourceProvider = Provider<ClassesDatasource>(
  (ref) => ClassesDatasource(ref.watch(apiClientProvider)),
);

final classesRepositoryProvider = Provider<ClassesRepository>(
  (ref) => ClassesRepositoryImpl(ref.watch(classesDatasourceProvider)),
);

/// Turmas do ano letivo efetivo (selecionado globalmente).
final classesListProvider = FutureProvider<List<SchoolClass>>((ref) {
  final yearId = ref.watch(effectiveAcademicYearIdProvider);
  if (yearId == null) return Future.value(const []);
  return ref.watch(classesRepositoryProvider).getClasses(academicYearId: yearId);
});

final classDetailProvider = FutureProvider.family<SchoolClass, String>((ref, id) {
  return ref.watch(classesRepositoryProvider).getClass(id);
});

final enrollmentsProvider = FutureProvider.family<List<Enrollment>, String>((ref, classId) {
  return ref.watch(classesRepositoryProvider).getEnrollments(classId);
});

/// Disciplinas vinculadas a uma turma (`GET /classes/{classId}/disciplines`).
final classDisciplinesProvider = FutureProvider.family<List<Discipline>, String>((ref, classId) {
  return ref.watch(classesRepositoryProvider).getClassDisciplines(classId);
});

class ClassesActions {
  ClassesActions(this._ref);

  final Ref _ref;

  ClassesRepository get _repo => _ref.read(classesRepositoryProvider);

  Future<SchoolClass> create({
    required String academicYearId,
    required String courseId,
    required List<String> disciplineIds,
    required String name,
    String? shift,
  }) async {
    final result = await _repo.createClass(
      academicYearId: academicYearId,
      courseId: courseId,
      disciplineIds: disciplineIds,
      name: name,
      shift: shift,
    );
    _ref.invalidate(classesListProvider);
    return result;
  }

  Future<void> update(String id, {String? name, String? shift}) async {
    await _repo.updateClass(id, name: name, shift: shift);
    _ref.invalidate(classesListProvider);
    _ref.invalidate(classDetailProvider(id));
  }

  Future<void> archive(String id) async {
    await _repo.archiveClass(id);
    _ref.invalidate(classesListProvider);
    _ref.invalidate(classDetailProvider(id));
  }

  Future<void> enroll(String classId, String studentId) async {
    await _repo.enrollStudent(classId, studentId);
    _ref.invalidate(enrollmentsProvider(classId));
  }

  Future<void> unenroll(String classId, String studentId) async {
    await _repo.unenrollStudent(classId, studentId);
    _ref.invalidate(enrollmentsProvider(classId));
  }

  Future<void> linkDiscipline(String classId, String disciplineId) async {
    await _repo.linkDisciplineToClass(classId, disciplineId);
    _ref.invalidate(classDetailProvider(classId));
    _ref.invalidate(classDisciplinesProvider(classId));
    _ref.invalidate(classesListProvider);
  }

  Future<void> unlinkDiscipline(String classId, String disciplineId) async {
    await _repo.unlinkDisciplineFromClass(classId, disciplineId);
    _ref.invalidate(classDetailProvider(classId));
    _ref.invalidate(classDisciplinesProvider(classId));
    _ref.invalidate(classesListProvider);
  }
}

final classesActionsProvider = Provider<ClassesActions>((ref) => ClassesActions(ref));
