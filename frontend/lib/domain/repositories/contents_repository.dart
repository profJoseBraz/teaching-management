import '../entities/content_item.dart';

abstract interface class ContentsRepository {
  Future<List<ContentItem>> getContents(
    String classId, {
    String? status,
    String? disciplineId,
    String? assessmentPeriodId,
  });
  Future<ContentItem> createContent(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
    required String title,
    String? description,
  });
  Future<ContentItem> updateContent(
    String id, {
    String? title,
    String? description,
    String? assessmentPeriodId,
  });
  Future<ContentItem> completeContent(String id);
  Future<ContentItem> reopenContent(String id);
  Future<void> linkContentToLesson(String lessonId, String contentId);
  Future<void> unlinkContentFromLesson(String lessonId, String contentId);
}
