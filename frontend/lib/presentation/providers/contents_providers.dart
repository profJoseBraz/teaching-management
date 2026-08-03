import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/contents_datasource.dart';
import '../../data/repositories/contents_repository_impl.dart';
import '../../domain/entities/content_item.dart';
import '../../domain/repositories/contents_repository.dart';
import 'session_providers.dart';

final contentsDatasourceProvider = Provider<ContentsDatasource>(
  (ref) => ContentsDatasource(ref.watch(apiClientProvider)),
);

final contentsRepositoryProvider = Provider<ContentsRepository>(
  (ref) => ContentsRepositoryImpl(ref.watch(contentsDatasourceProvider)),
);

/// Filtro de listagem: turma obrigatória + disciplina opcional (`null` =
/// todas as disciplinas vinculadas à turma).
typedef ContentsQuery = ({String classId, String? disciplineId});

final contentsListProvider = FutureProvider.family<List<ContentItem>, ContentsQuery>((ref, query) {
  return ref.watch(contentsRepositoryProvider).getContents(query.classId, disciplineId: query.disciplineId);
});

class ContentsActions {
  ContentsActions(this._ref);

  final Ref _ref;

  ContentsRepository get _repo => _ref.read(contentsRepositoryProvider);

  Future<void> create(String classId, {required String disciplineId, required String title, String? description}) async {
    await _repo.createContent(classId, disciplineId: disciplineId, title: title, description: description);
    _ref.invalidate(contentsListProvider);
  }

  Future<void> update(String id, {required String classId, String? title, String? description}) async {
    await _repo.updateContent(id, title: title, description: description);
    _ref.invalidate(contentsListProvider);
  }

  Future<void> complete(String id, {required String classId}) async {
    await _repo.completeContent(id);
    _ref.invalidate(contentsListProvider);
  }

  Future<void> reopen(String id, {required String classId}) async {
    await _repo.reopenContent(id);
    _ref.invalidate(contentsListProvider);
  }

  Future<void> linkToLesson(String lessonId, String contentId, {required String classId}) async {
    await _repo.linkContentToLesson(lessonId, contentId);
    _ref.invalidate(contentsListProvider);
  }

  Future<void> unlinkFromLesson(String lessonId, String contentId, {required String classId}) async {
    await _repo.unlinkContentFromLesson(lessonId, contentId);
    _ref.invalidate(contentsListProvider);
  }
}

final contentsActionsProvider = Provider<ContentsActions>((ref) => ContentsActions(ref));
