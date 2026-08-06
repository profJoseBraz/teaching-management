import '../../core/network/api_client.dart';
import '../../domain/entities/content_item.dart';

ContentItem contentItemFromJson(Map<String, dynamic> json) => ContentItem(
      id: json['id'] as String,
      classId: json['classId'] as String,
      disciplineId: json['disciplineId'] as String,
      assessmentPeriodId: json['assessmentPeriodId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'IN_PROGRESS',
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );

/// Fala com `/classes/{classId}/contents`, `/contents/{id}` e os vínculos
/// conteúdo <-> aula.
class ContentsDatasource {
  ContentsDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ContentItem>> getContents(
    String classId, {
    String? status,
    String? disciplineId,
    String? assessmentPeriodId,
  }) async {
    final response = await _apiClient.get(
      '/classes/$classId/contents',
      query: {
        'status': status,
        'disciplineId': disciplineId,
        'assessmentPeriodId': assessmentPeriodId,
      },
    );
    return (response['data'] as List).map((e) => contentItemFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ContentItem> createContent(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
    required String title,
    String? description,
  }) async {
    final response = await _apiClient.post('/classes/$classId/contents', data: {
      'disciplineId': disciplineId,
      'assessmentPeriodId': assessmentPeriodId,
      'title': title,
      if (description != null) 'description': description,
    });
    return contentItemFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ContentItem> updateContent(
    String id, {
    String? title,
    String? description,
    String? assessmentPeriodId,
  }) async {
    final response = await _apiClient.patch('/contents/$id', data: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (assessmentPeriodId != null) 'assessmentPeriodId': assessmentPeriodId,
    });
    return contentItemFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ContentItem> completeContent(String id) async {
    final response = await _apiClient.post('/contents/$id/complete');
    return contentItemFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ContentItem> reopenContent(String id) async {
    final response = await _apiClient.post('/contents/$id/reopen');
    return contentItemFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> linkContentToLesson(String lessonId, String contentId) => _apiClient.post(
        '/lessons/$lessonId/contents',
        data: {'contentId': contentId},
      );

  Future<void> unlinkContentFromLesson(String lessonId, String contentId) =>
      _apiClient.delete('/lessons/$lessonId/contents/$contentId');
}
