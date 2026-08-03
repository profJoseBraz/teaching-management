import '../../core/network/api_client.dart';
import '../../domain/entities/attention_item.dart';

AttentionItem attentionItemFromJson(Map<String, dynamic> json) => AttentionItem(
      id: json['id'] as String,
      type: json['type'] as String,
      severity: json['severity'] as String? ?? 'low',
      title: json['title'] as String,
      message: json['message'] as String,
      count: json['count'] as int? ?? 0,
      actionRoute: json['actionRoute'] as String?,
      filters: (json['filters'] as Map?)?.cast<String, dynamic>() ?? const {},
    );

DashboardSummary _summaryFromJson(Map<String, dynamic> json) => DashboardSummary(
      totalAttentionItems: json['totalAttentionItems'] as int? ?? 0,
      totalPendingActions: json['totalPendingActions'] as int? ?? 0,
      bySeverity: (json['bySeverity'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ??
          const {'high': 0, 'medium': 0, 'low': 0},
    );

/// Fala com `/dashboard` e `/attention-items` (Insights Engine).
class DashboardDatasource {
  DashboardDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardResponse> getDashboard({String? academicYearId, String? classId}) async {
    final response = await _apiClient.get('/dashboard', query: {
      'academicYearId': academicYearId,
      'classId': classId,
    });
    final data = response['data'] as Map<String, dynamic>;
    return DashboardResponse(
      attentionItems: (data['attentionItems'] as List)
          .map((e) => attentionItemFromJson(e as Map<String, dynamic>))
          .toList(),
      summary: _summaryFromJson(data['summary'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Future<List<AttentionItem>> getAttentionItems({String? academicYearId, String? classId}) async {
    final response = await _apiClient.get('/attention-items', query: {
      'academicYearId': academicYearId,
      'classId': classId,
    });
    final data = response['data'] as Map<String, dynamic>;
    return (data['attentionItems'] as List)
        .map((e) => attentionItemFromJson(e as Map<String, dynamic>))
        .toList();
  }
}
