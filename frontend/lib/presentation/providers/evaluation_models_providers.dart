import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../data/datasources/evaluation_models_datasource.dart';
import '../../data/repositories/evaluation_models_repository_impl.dart';
import '../../domain/entities/evaluation_model.dart';
import '../../domain/repositories/evaluation_models_repository.dart';
import 'session_providers.dart';

final evaluationModelsDatasourceProvider = Provider<EvaluationModelsDatasource>(
  (ref) => EvaluationModelsDatasource(ref.watch(apiClientProvider)),
);

final evaluationModelsRepositoryProvider = Provider<EvaluationModelsRepository>(
  (ref) => EvaluationModelsRepositoryImpl(ref.watch(evaluationModelsDatasourceProvider)),
);

final evaluationModelsProvider = FutureProvider<List<EvaluationModel>>((ref) {
  return ref.watch(evaluationModelsRepositoryProvider).list(includeInactive: true);
});

final activeEvaluationModelsProvider = FutureProvider<List<EvaluationModel>>((ref) async {
  final models = await ref.watch(evaluationModelsRepositoryProvider).list(includeInactive: false);
  return models.where((m) => m.isActive).toList();
});

class EvaluationModelsActions {
  EvaluationModelsActions(this._ref);

  final Ref _ref;

  EvaluationModelsRepository get _repo => _ref.read(evaluationModelsRepositoryProvider);

  void _invalidate() => _ref.invalidate(evaluationModelsProvider);

  Future<EvaluationModel?> create({
    required String name,
    String? description,
    List<({String name, double maxScore})>? items,
  }) async {
    try {
      final model = await _repo.create(name: name, description: description, items: items);
      _invalidate();
      return model;
    } on AppException {
      rethrow;
    }
  }

  Future<void> update(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    await _repo.update(id, name: name, description: description, isActive: isActive);
    _invalidate();
  }

  Future<void> deactivate(String id) async {
    await _repo.deactivate(id);
    _invalidate();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _invalidate();
  }

  Future<void> createItem(
    String modelId, {
    required String name,
    required double maxScore,
    bool isRecovery = false,
    String? recoversItemId,
  }) async {
    await _repo.createItem(
      modelId,
      name: name,
      maxScore: maxScore,
      isRecovery: isRecovery,
      recoversItemId: recoversItemId,
    );
    _invalidate();
  }

  Future<void> updateItem(
    String modelId,
    String itemId, {
    String? name,
    double? maxScore,
    bool? isRecovery,
    String? recoversItemId,
  }) async {
    await _repo.updateItem(
      modelId,
      itemId,
      name: name,
      maxScore: maxScore,
      isRecovery: isRecovery,
      recoversItemId: recoversItemId,
    );
    _invalidate();
  }

  Future<void> deleteItem(String modelId, String itemId) async {
    await _repo.deleteItem(modelId, itemId);
    _invalidate();
  }

  Future<void> reorderItems(String modelId, List<String> itemIds) async {
    await _repo.reorderItems(modelId, itemIds);
    _invalidate();
  }
}

final evaluationModelsActionsProvider = Provider<EvaluationModelsActions>(
  (ref) => EvaluationModelsActions(ref),
);
