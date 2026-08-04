import '../../domain/entities/bulk_create_students_result.dart';
import '../../domain/entities/student.dart';
import '../../domain/entities/student_paste_preview.dart';
import '../../domain/repositories/students_repository.dart';
import '../datasources/students_datasource.dart';

class StudentsRepositoryImpl implements StudentsRepository {
  StudentsRepositoryImpl(this._datasource);

  final StudentsDatasource _datasource;

  @override
  Future<List<Student>> getStudents({String? search}) => _datasource.getStudents(search: search);

  @override
  Future<Student> getStudent(String id) => _datasource.getStudent(id);

  @override
  Future<Student> createStudent({
    required String name,
    String? registryCode,
    String? email,
    String? phone,
    String? notes,
  }) =>
      _datasource.createStudent(
        name: name,
        registryCode: registryCode,
        email: email,
        phone: phone,
        notes: notes,
      );

  @override
  Future<BulkCreateStudentsResult> bulkCreateStudents({required String text}) =>
      _datasource.bulkCreateStudents(text: text);

  @override
  Future<StudentPastePreview> previewStudentPaste({required String text}) =>
      _datasource.previewStudentPaste(text: text);

  @override
  Future<List<Student>> createStudentsBatch(
    List<({
      String name,
      String? registryCode,
      String? email,
      String? phone,
      String? notes,
    })> students,
  ) =>
      _datasource.createStudentsBatch(students);

  @override
  Future<Student> updateStudent(
    String id, {
    String? name,
    String? registryCode,
    String? email,
    String? phone,
    String? notes,
  }) =>
      _datasource.updateStudent(
        id,
        name: name,
        registryCode: registryCode,
        email: email,
        phone: phone,
        notes: notes,
      );

  @override
  Future<void> deleteStudent(String id) => _datasource.deleteStudent(id);
}
