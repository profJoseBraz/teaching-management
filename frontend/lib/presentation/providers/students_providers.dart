import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/students_datasource.dart';
import '../../data/repositories/students_repository_impl.dart';
import '../../domain/entities/bulk_create_students_result.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_paste_preview.dart';
import '../../domain/repositories/students_repository.dart';
import 'session_providers.dart';

final studentsDatasourceProvider = Provider<StudentsDatasource>(
  (ref) => StudentsDatasource(ref.watch(apiClientProvider)),
);

final studentsRepositoryProvider = Provider<StudentsRepository>(
  (ref) => StudentsRepositoryImpl(ref.watch(studentsDatasourceProvider)),
);

/// Termo de busca atual da tela de alunos.
final studentSearchQueryProvider = StateProvider<String>((ref) => '');

final studentsListProvider = FutureProvider<List<Student>>((ref) {
  final search = ref.watch(studentSearchQueryProvider);
  return ref.watch(studentsRepositoryProvider).getStudents(search: search.isEmpty ? null : search).then(
    (students) {
      students.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return students;
    },
  );
});

final studentDetailProvider = FutureProvider.family<Student, String>((ref, id) {
  return ref.watch(studentsRepositoryProvider).getStudent(id);
});

class StudentsActions {
  StudentsActions(this._ref);

  final Ref _ref;

  StudentsRepository get _repo => _ref.read(studentsRepositoryProvider);

  Future<void> create({
    required String name,
    String? registryCode,
    String? email,
    String? phone,
    String? notes,
  }) async {
    await _repo.createStudent(name: name, registryCode: registryCode, email: email, phone: phone, notes: notes);
    _ref.invalidate(studentsListProvider);
  }

  Future<BulkCreateStudentsResult> bulkCreate({required String text}) async {
    final result = await _repo.bulkCreateStudents(text: text);
    _ref.invalidate(studentsListProvider);
    return result;
  }

  Future<StudentPastePreview> previewPaste({required String text}) {
    return _repo.previewStudentPaste(text: text);
  }

  Future<List<Student>> createBatch(
    List<({
      String name,
      String? registryCode,
      String? email,
      String? phone,
      String? notes,
    })> students,
  ) async {
    final created = await _repo.createStudentsBatch(students);
    _ref.invalidate(studentsListProvider);
    return created;
  }

  Future<void> update(
    String id, {
    String? name,
    String? registryCode,
    String? email,
    String? phone,
    String? notes,
  }) async {
    await _repo.updateStudent(id, name: name, registryCode: registryCode, email: email, phone: phone, notes: notes);
    _ref.invalidate(studentsListProvider);
  }

  Future<void> delete(String id) async {
    await _repo.deleteStudent(id);
    _ref.invalidate(studentsListProvider);
  }
}

final studentsActionsProvider = Provider<StudentsActions>((ref) => StudentsActions(ref));
