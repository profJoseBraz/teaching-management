import '../entities/academic_year.dart';
import '../entities/assessment_period.dart';
import '../entities/course.dart';
import '../entities/course_discipline.dart';
import '../entities/discipline.dart';

abstract interface class AcademicRepository {
  // Academic years
  Future<List<AcademicYear>> getAcademicYears();
  Future<AcademicYear> createAcademicYear({
    required int year,
    String? label,
    DateTime? startsOn,
    DateTime? endsOn,
  });
  Future<AcademicYear> updateAcademicYear(
    String id, {
    String? label,
    DateTime? startsOn,
    DateTime? endsOn,
  });
  Future<AcademicYear> setCurrentAcademicYear(String id);

  // Courses
  Future<List<Course>> getCourses();
  Future<Course> createCourse({required String name, String? description});
  Future<Course> updateCourse(String id, {required String name, String? description});
  Future<void> deleteCourse(String id);

  // Disciplines
  Future<List<Discipline>> getDisciplines();
  Future<Discipline> createDiscipline({required String name, String? description});
  Future<Discipline> updateDiscipline(String id, {String? name, String? description});
  Future<void> deleteDiscipline(String id);

  // Course <-> Discipline links
  Future<List<CourseDiscipline>> getCourseDisciplines(String courseId);
  Future<CourseDiscipline> linkDisciplineToCourse(String courseId, String disciplineId);
  Future<void> unlinkDisciplineFromCourse(String courseId, String disciplineId);

  // Assessment periods
  Future<List<AssessmentPeriod>> getAssessmentPeriods(String academicYearId);
  Future<AssessmentPeriod> createAssessmentPeriod({
    required String academicYearId,
    String? classId,
    required String name,
    DateTime? startsOn,
    DateTime? endsOn,
  });
  Future<AssessmentPeriod> updateAssessmentPeriod(
    String id, {
    String? name,
    DateTime? startsOn,
    DateTime? endsOn,
  });
  Future<List<AssessmentPeriod>> reorderAssessmentPeriods({
    required String academicYearId,
    required List<String> orderedIds,
  });
}
