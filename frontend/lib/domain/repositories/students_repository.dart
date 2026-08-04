import '../entities/bulk_create_students_result.dart';
import '../entities/student.dart';
import '../entities/student_paste_preview.dart';

abstract interface class StudentsRepository {
  Future<List<Student>> getStudents({String? search});
  Future<Student> getStudent(String id);
  Future<Student> createStudent({
    required String name,
    String? registryCode,
    String? email,
    String? phone,
    String? notes,
  });
  Future<BulkCreateStudentsResult> bulkCreateStudents({required String text});
  Future<StudentPastePreview> previewStudentPaste({required String text});
  Future<List<Student>> createStudentsBatch(
    List<({
      String name,
      String? registryCode,
      String? email,
      String? phone,
      String? notes,
    })> students,
  );
  Future<Student> updateStudent(
    String id, {
    String? name,
    String? registryCode,
    String? email,
    String? phone,
    String? notes,
  });
  Future<void> deleteStudent(String id);
}
