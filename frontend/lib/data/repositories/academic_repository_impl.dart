import '../../domain/entities/academic_year.dart';
import '../../domain/entities/assessment_period.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_discipline.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/repositories/academic_repository.dart';
import '../datasources/academic_datasource.dart';

class AcademicRepositoryImpl implements AcademicRepository {
  AcademicRepositoryImpl(this._datasource);

  final AcademicDatasource _datasource;

  @override
  Future<List<AcademicYear>> getAcademicYears() => _datasource.getAcademicYears();

  @override
  Future<AcademicYear> createAcademicYear({
    required int year,
    String? label,
    DateTime? startsOn,
    DateTime? endsOn,
  }) =>
      _datasource.createAcademicYear(year: year, label: label, startsOn: startsOn, endsOn: endsOn);

  @override
  Future<AcademicYear> updateAcademicYear(String id, {String? label, DateTime? startsOn, DateTime? endsOn}) =>
      _datasource.updateAcademicYear(id, label: label, startsOn: startsOn, endsOn: endsOn);

  @override
  Future<AcademicYear> setCurrentAcademicYear(String id) => _datasource.setCurrentAcademicYear(id);

  @override
  Future<List<Course>> getCourses() => _datasource.getCourses();

  @override
  Future<Course> createCourse({required String name, String? description}) =>
      _datasource.createCourse(name: name, description: description);

  @override
  Future<Course> updateCourse(String id, {String? name, String? description}) =>
      _datasource.updateCourse(id, name: name, description: description);

  @override
  Future<void> deleteCourse(String id) => _datasource.deleteCourse(id);

  @override
  Future<List<Discipline>> getDisciplines() => _datasource.getDisciplines();

  @override
  Future<Discipline> createDiscipline({required String name, String? description}) =>
      _datasource.createDiscipline(name: name, description: description);

  @override
  Future<Discipline> updateDiscipline(String id, {String? name, String? description}) =>
      _datasource.updateDiscipline(id, name: name, description: description);

  @override
  Future<void> deleteDiscipline(String id) => _datasource.deleteDiscipline(id);

  @override
  Future<List<CourseDiscipline>> getCourseDisciplines(String courseId) =>
      _datasource.getCourseDisciplines(courseId);

  @override
  Future<CourseDiscipline> linkDisciplineToCourse(String courseId, String disciplineId) =>
      _datasource.linkDisciplineToCourse(courseId, disciplineId);

  @override
  Future<void> unlinkDisciplineFromCourse(String courseId, String disciplineId) =>
      _datasource.unlinkDisciplineFromCourse(courseId, disciplineId);

  @override
  Future<List<AssessmentPeriod>> getAssessmentPeriods(String academicYearId) =>
      _datasource.getAssessmentPeriods(academicYearId);

  @override
  Future<AssessmentPeriod> createAssessmentPeriod({
    required String academicYearId,
    String? classId,
    required String name,
    DateTime? startsOn,
    DateTime? endsOn,
  }) =>
      _datasource.createAssessmentPeriod(
        academicYearId: academicYearId,
        classId: classId,
        name: name,
        startsOn: startsOn,
        endsOn: endsOn,
      );

  @override
  Future<AssessmentPeriod> updateAssessmentPeriod(String id, {String? name, DateTime? startsOn, DateTime? endsOn}) =>
      _datasource.updateAssessmentPeriod(id, name: name, startsOn: startsOn, endsOn: endsOn);

  @override
  Future<List<AssessmentPeriod>> reorderAssessmentPeriods({
    required String academicYearId,
    required List<String> orderedIds,
  }) =>
      _datasource.reorderAssessmentPeriods(academicYearId: academicYearId, orderedIds: orderedIds);
}
