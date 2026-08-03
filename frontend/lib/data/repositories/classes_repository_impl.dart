import '../../domain/entities/discipline.dart';
import '../../domain/entities/enrollment.dart';
import '../../domain/entities/school_class.dart';
import '../../domain/repositories/classes_repository.dart';
import '../datasources/classes_datasource.dart';

class ClassesRepositoryImpl implements ClassesRepository {
  ClassesRepositoryImpl(this._datasource);

  final ClassesDatasource _datasource;

  @override
  Future<List<SchoolClass>> getClasses({
    String? academicYearId,
    String? courseId,
    String? disciplineId,
    String? status,
  }) =>
      _datasource.getClasses(
        academicYearId: academicYearId,
        courseId: courseId,
        disciplineId: disciplineId,
        status: status,
      );

  @override
  Future<SchoolClass> getClass(String id) => _datasource.getClass(id);

  @override
  Future<SchoolClass> createClass({
    required String academicYearId,
    required String courseId,
    required List<String> disciplineIds,
    required String name,
    String? shift,
  }) =>
      _datasource.createClass(
        academicYearId: academicYearId,
        courseId: courseId,
        disciplineIds: disciplineIds,
        name: name,
        shift: shift,
      );

  @override
  Future<SchoolClass> updateClass(String id, {String? name, String? shift}) =>
      _datasource.updateClass(id, name: name, shift: shift);

  @override
  Future<SchoolClass> archiveClass(String id) => _datasource.archiveClass(id);

  @override
  Future<List<Enrollment>> getEnrollments(String classId) => _datasource.getEnrollments(classId);

  @override
  Future<Enrollment> enrollStudent(String classId, String studentId) =>
      _datasource.enrollStudent(classId, studentId);

  @override
  Future<void> unenrollStudent(String classId, String studentId) =>
      _datasource.unenrollStudent(classId, studentId);

  @override
  Future<List<Discipline>> getClassDisciplines(String classId) => _datasource.getClassDisciplines(classId);

  @override
  Future<void> linkDisciplineToClass(String classId, String disciplineId) =>
      _datasource.linkDisciplineToClass(classId, disciplineId);

  @override
  Future<void> unlinkDisciplineFromClass(String classId, String disciplineId) =>
      _datasource.unlinkDisciplineFromClass(classId, disciplineId);
}
