import '../../domain/entities/content_item.dart';
import '../../domain/repositories/contents_repository.dart';
import '../datasources/contents_datasource.dart';

class ContentsRepositoryImpl implements ContentsRepository {
  ContentsRepositoryImpl(this._datasource);

  final ContentsDatasource _datasource;

  @override
  Future<List<ContentItem>> getContents(
    String classId, {
    String? status,
    String? disciplineId,
    String? assessmentPeriodId,
  }) =>
      _datasource.getContents(
        classId,
        status: status,
        disciplineId: disciplineId,
        assessmentPeriodId: assessmentPeriodId,
      );

  @override
  Future<ContentItem> createContent(
    String classId, {
    required String disciplineId,
    required String assessmentPeriodId,
    required String title,
    String? description,
  }) =>
      _datasource.createContent(
        classId,
        disciplineId: disciplineId,
        assessmentPeriodId: assessmentPeriodId,
        title: title,
        description: description,
      );

  @override
  Future<ContentItem> updateContent(
    String id, {
    String? title,
    String? description,
    String? assessmentPeriodId,
  }) =>
      _datasource.updateContent(
        id,
        title: title,
        description: description,
        assessmentPeriodId: assessmentPeriodId,
      );

  @override
  Future<ContentItem> completeContent(String id) => _datasource.completeContent(id);

  @override
  Future<ContentItem> reopenContent(String id) => _datasource.reopenContent(id);

  @override
  Future<void> linkContentToLesson(String lessonId, String contentId) =>
      _datasource.linkContentToLesson(lessonId, contentId);

  @override
  Future<void> unlinkContentFromLesson(String lessonId, String contentId) =>
      _datasource.unlinkContentFromLesson(lessonId, contentId);
}
