import '../../core/network/api_client.dart';
import '../../domain/entities/academic_year.dart';
import '../../domain/entities/assessment_period.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_discipline.dart';
import '../../domain/entities/discipline.dart';

DateTime? _parseDate(dynamic value) => value == null ? null : DateTime.parse(value as String);

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

AcademicYear academicYearFromJson(Map<String, dynamic> json) => AcademicYear(
      id: json['id'] as String,
      year: json['year'] as int,
      label: json['label'] as String?,
      isCurrent: json['isCurrent'] as bool? ?? false,
      startsOn: _parseDate(json['startsOn']),
      endsOn: _parseDate(json['endsOn']),
    );

Course courseFromJson(Map<String, dynamic> json) => Course(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Discipline disciplineFromJson(Map<String, dynamic> json) => Discipline(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

CourseDiscipline courseDisciplineFromJson(Map<String, dynamic> json) => CourseDiscipline(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      disciplineId: json['disciplineId'] as String,
      discipline: json['discipline'] != null
          ? disciplineFromJson(json['discipline'] as Map<String, dynamic>)
          : null,
    );

AssessmentPeriod assessmentPeriodFromJson(Map<String, dynamic> json) => AssessmentPeriod(
      id: json['id'] as String,
      academicYearId: json['academicYearId'] as String,
      classId: json['classId'] as String?,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      startsOn: _parseDate(json['startsOn']),
      endsOn: _parseDate(json['endsOn']),
    );

/// Fala com os endpoints de estrutura acadêmica: anos letivos, cursos,
/// disciplinas, vínculos curso-disciplina e períodos avaliativos.
class AcademicDatasource {
  AcademicDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AcademicYear>> getAcademicYears() async {
    final response = await _apiClient.get('/academic-years');
    return (response['data'] as List)
        .map((e) => academicYearFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AcademicYear> createAcademicYear({
    required int year,
    String? label,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    final response = await _apiClient.post('/academic-years', data: {
      'year': year,
      if (label != null) 'label': label,
      if (startsOn != null) 'startsOn': _formatDate(startsOn),
      if (endsOn != null) 'endsOn': _formatDate(endsOn),
    });
    return academicYearFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AcademicYear> updateAcademicYear(
    String id, {
    String? label,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    final response = await _apiClient.patch('/academic-years/$id', data: {
      if (label != null) 'label': label,
      if (startsOn != null) 'startsOn': _formatDate(startsOn),
      if (endsOn != null) 'endsOn': _formatDate(endsOn),
    });
    return academicYearFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AcademicYear> setCurrentAcademicYear(String id) async {
    final response = await _apiClient.post('/academic-years/$id/set-current');
    return academicYearFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Course>> getCourses() async {
    final response = await _apiClient.get('/courses');
    return (response['data'] as List).map((e) => courseFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Course> createCourse({required String name, String? description}) async {
    final response = await _apiClient.post('/courses', data: {
      'name': name,
      if (description != null) 'description': description,
    });
    return courseFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Course> updateCourse(String id, {String? name, String? description}) async {
    final response = await _apiClient.patch('/courses/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    });
    return courseFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteCourse(String id) => _apiClient.delete('/courses/$id');

  Future<List<Discipline>> getDisciplines() async {
    final response = await _apiClient.get('/disciplines');
    return (response['data'] as List)
        .map((e) => disciplineFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Discipline> createDiscipline({required String name, String? description}) async {
    final response = await _apiClient.post('/disciplines', data: {
      'name': name,
      if (description != null) 'description': description,
    });
    return disciplineFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Discipline> updateDiscipline(String id, {String? name, String? description}) async {
    final response = await _apiClient.patch('/disciplines/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    });
    return disciplineFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteDiscipline(String id) => _apiClient.delete('/disciplines/$id');

  Future<List<CourseDiscipline>> getCourseDisciplines(String courseId) async {
    final response = await _apiClient.get('/courses/$courseId/disciplines');
    return (response['data'] as List)
        .map((e) => courseDisciplineFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CourseDiscipline> linkDisciplineToCourse(String courseId, String disciplineId) async {
    final response = await _apiClient.post(
      '/courses/$courseId/disciplines',
      data: {'disciplineId': disciplineId},
    );
    return courseDisciplineFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> unlinkDisciplineFromCourse(String courseId, String disciplineId) =>
      _apiClient.delete('/courses/$courseId/disciplines/$disciplineId');

  Future<List<AssessmentPeriod>> getAssessmentPeriods(String academicYearId) async {
    final response = await _apiClient.get(
      '/assessment-periods',
      query: {'academicYearId': academicYearId},
    );
    return (response['data'] as List)
        .map((e) => assessmentPeriodFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AssessmentPeriod> createAssessmentPeriod({
    required String academicYearId,
    String? classId,
    required String name,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    final response = await _apiClient.post('/assessment-periods', data: {
      'academicYearId': academicYearId,
      if (classId != null) 'classId': classId,
      'name': name,
      if (startsOn != null) 'startsOn': _formatDate(startsOn),
      if (endsOn != null) 'endsOn': _formatDate(endsOn),
    });
    return assessmentPeriodFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AssessmentPeriod> updateAssessmentPeriod(
    String id, {
    String? name,
    DateTime? startsOn,
    DateTime? endsOn,
  }) async {
    final response = await _apiClient.patch('/assessment-periods/$id', data: {
      if (name != null) 'name': name,
      if (startsOn != null) 'startsOn': _formatDate(startsOn),
      if (endsOn != null) 'endsOn': _formatDate(endsOn),
    });
    return assessmentPeriodFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<AssessmentPeriod>> reorderAssessmentPeriods({
    required String academicYearId,
    required List<String> orderedIds,
  }) async {
    final response = await _apiClient.put('/assessment-periods/reorder', data: {
      'academicYearId': academicYearId,
      'orderedIds': orderedIds,
    });
    return (response['data'] as List)
        .map((e) => assessmentPeriodFromJson(e as Map<String, dynamic>))
        .toList();
  }
}
