import '../../core/network/api_client.dart';
import '../../domain/entities/report_result.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

ReportResult reportResultFromJson(Map<String, dynamic> json) => ReportResult(
      reportType: json['reportType'] as String,
      filters: (json['filters'] as Map?)?.cast<String, dynamic>() ?? const {},
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      rows: (json['rows'] as List? ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList(),
      totalRows: json['totalRows'] as int? ?? 0,
    );

/// Fala com `/reports/{reportType}`.
class ReportsDatasource {
  ReportsDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<ReportResult> runReport(
    String reportType, {
    String? academicYearId,
    String? courseId,
    String? disciplineId,
    String? classId,
    String? assessmentPeriodId,
    DateTime? from,
    DateTime? to,
    int? threshold,
  }) async {
    final response = await _apiClient.get('/reports/$reportType', query: {
      'academicYearId': academicYearId,
      'courseId': courseId,
      'disciplineId': disciplineId,
      'classId': classId,
      'assessmentPeriodId': assessmentPeriodId,
      'from': from != null ? _formatDate(from) : null,
      'to': to != null ? _formatDate(to) : null,
      'threshold': threshold,
    });
    return reportResultFromJson(response['data'] as Map<String, dynamic>);
  }
}
