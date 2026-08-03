import '../../core/network/api_client.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/enrollment.dart';
import '../../domain/entities/school_class.dart';
import 'academic_datasource.dart';
import 'students_datasource.dart';

SchoolClass schoolClassFromJson(Map<String, dynamic> json) => SchoolClass(
      id: json['id'] as String,
      academicYearId: json['academicYearId'] as String,
      courseId: json['courseId'] as String,
      disciplineIds: (json['disciplineIds'] as List? ?? const []).cast<String>(),
      disciplines: (json['disciplines'] as List? ?? const [])
          .map((e) => _classDisciplineRefFromJson(e as Map<String, dynamic>))
          .toList(),
      name: json['name'] as String,
      shift: json['shift'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );

ClassDisciplineRef _classDisciplineRefFromJson(Map<String, dynamic> json) => ClassDisciplineRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );

/// Disciplina vinculada a uma turma, no formato enriquecido devolvido por
/// `GET /classes/{classId}/disciplines` (inclui `description`).
Discipline classDisciplineLinkFromJson(Map<String, dynamic> json) =>
    disciplineFromJson(json['discipline'] as Map<String, dynamic>);

Enrollment enrollmentFromJson(Map<String, dynamic> json) => Enrollment(
      id: json['id'] as String,
      classId: json['classId'] as String,
      studentId: json['studentId'] as String,
      status: json['status'] as String? ?? 'ACTIVE',
      student: json['student'] != null ? studentFromJson(json['student'] as Map<String, dynamic>) : null,
    );

/// Fala com `/classes` e os sub-recursos de matrícula e disciplinas.
class ClassesDatasource {
  ClassesDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SchoolClass>> getClasses({
    String? academicYearId,
    String? courseId,
    String? disciplineId,
    String? status,
  }) async {
    final response = await _apiClient.get('/classes', query: {
      'academicYearId': academicYearId,
      'courseId': courseId,
      'disciplineId': disciplineId,
      'status': status,
    });
    return (response['data'] as List)
        .map((e) => schoolClassFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SchoolClass> getClass(String id) async {
    final response = await _apiClient.get('/classes/$id');
    return schoolClassFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<SchoolClass> createClass({
    required String academicYearId,
    required String courseId,
    required List<String> disciplineIds,
    required String name,
    String? shift,
  }) async {
    final response = await _apiClient.post('/classes', data: {
      'academicYearId': academicYearId,
      'courseId': courseId,
      'disciplineIds': disciplineIds,
      'name': name,
      if (shift != null) 'shift': shift,
    });
    return schoolClassFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<SchoolClass> updateClass(String id, {String? name, String? shift}) async {
    final response = await _apiClient.patch('/classes/$id', data: {
      if (name != null) 'name': name,
      if (shift != null) 'shift': shift,
    });
    return schoolClassFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<SchoolClass> archiveClass(String id) async {
    final response = await _apiClient.post('/classes/$id/archive');
    return schoolClassFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Enrollment>> getEnrollments(String classId) async {
    final response = await _apiClient.get('/classes/$classId/enrollments');
    return (response['data'] as List).map((e) => enrollmentFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Enrollment> enrollStudent(String classId, String studentId) async {
    final response = await _apiClient.post(
      '/classes/$classId/enrollments',
      data: {'studentId': studentId},
    );
    return enrollmentFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> unenrollStudent(String classId, String studentId) =>
      _apiClient.delete('/classes/$classId/enrollments/$studentId');

  Future<List<Discipline>> getClassDisciplines(String classId) async {
    final response = await _apiClient.get('/classes/$classId/disciplines');
    return (response['data'] as List).map((e) => classDisciplineLinkFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> linkDisciplineToClass(String classId, String disciplineId) => _apiClient.post(
        '/classes/$classId/disciplines',
        data: {'disciplineId': disciplineId},
      );

  Future<void> unlinkDisciplineFromClass(String classId, String disciplineId) =>
      _apiClient.delete('/classes/$classId/disciplines/$disciplineId');
}
