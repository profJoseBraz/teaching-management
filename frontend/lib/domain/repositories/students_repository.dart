import '../entities/student.dart';

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
