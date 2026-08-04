import '../entities/discipline.dart';
import '../entities/enrollment.dart';
import '../entities/school_class.dart';

abstract interface class ClassesRepository {
  Future<List<SchoolClass>> getClasses({
    String? academicYearId,
    String? courseId,
    String? disciplineId,
    String? status,
  });
  Future<SchoolClass> getClass(String id);
  Future<SchoolClass> createClass({
    required String academicYearId,
    required String courseId,
    required List<String> disciplineIds,
    required String name,
    String? shift,
  });
  Future<SchoolClass> updateClass(String id, {required String name, String? shift});
  Future<SchoolClass> archiveClass(String id);

  Future<List<Enrollment>> getEnrollments(String classId);
  Future<Enrollment> enrollStudent(String classId, String studentId);
  Future<({int totalEnrolled, int skipped})> bulkEnrollStudents(
    String classId,
    List<String> studentIds,
  );
  Future<void> unenrollStudent(String classId, String studentId);

  Future<List<Discipline>> getClassDisciplines(String classId);
  Future<void> linkDisciplineToClass(String classId, String disciplineId);
  Future<void> unlinkDisciplineFromClass(String classId, String disciplineId);
}
