import '../../core/network/api_client.dart';
import '../../domain/entities/bulk_create_students_result.dart';
import '../../domain/entities/student.dart';

Student studentFromJson(Map<String, dynamic> json) => Student(
      id: json['id'] as String,
      name: json['name'] as String,
      registryCode: json['registryCode'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
    );

BulkCreateStudentsResult bulkCreateResultFromJson(Map<String, dynamic> json) {
  final created = (json['created'] as List? ?? [])
      .map((e) => studentFromJson(e as Map<String, dynamic>))
      .toList();
  final skipped = (json['skipped'] as List? ?? []).map((e) {
    final row = e as Map<String, dynamic>;
    return BulkCreateSkippedRow(
      lineNumber: row['lineNumber'] as int,
      line: row['line'] as String? ?? '',
      reason: row['reason'] as String? ?? '',
    );
  }).toList();

  return BulkCreateStudentsResult(
    created: created,
    skipped: skipped,
    totalParsed: json['totalParsed'] as int? ?? created.length,
    totalCreated: json['totalCreated'] as int? ?? created.length,
  );
}

/// Fala com `/students`.
class StudentsDatasource {
  StudentsDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Student>> getStudents({String? search}) async {
    final response = await _apiClient.get('/students', query: {'search': search});
    return (response['data'] as List).map((e) => studentFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Student> getStudent(String id) async {
    final response = await _apiClient.get('/students/$id');
    return studentFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Student> createStudent({
    required String name,
    String? registryCode,
    String? email,
    String? phone,
    String? notes,
  }) async {
    final response = await _apiClient.post('/students', data: {
      'name': name,
      if (registryCode != null) 'registryCode': registryCode,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (notes != null) 'notes': notes,
    });
    return studentFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<BulkCreateStudentsResult> bulkCreateStudents({required String text}) async {
    final response = await _apiClient.post('/students/bulk', data: {'text': text});
    return bulkCreateResultFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Student> updateStudent(
    String id, {
    String? name,
    String? registryCode,
    String? email,
    String? phone,
    String? notes,
  }) async {
    final response = await _apiClient.patch('/students/$id', data: {
      if (name != null) 'name': name,
      if (registryCode != null) 'registryCode': registryCode,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (notes != null) 'notes': notes,
    });
    return studentFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteStudent(String id) => _apiClient.delete('/students/$id');
}
