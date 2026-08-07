import '../../domain/entities/evaluation_model.dart';
import '../../domain/repositories/evaluation_models_repository.dart';
import '../datasources/evaluation_models_datasource.dart';

class EvaluationModelsRepositoryImpl implements EvaluationModelsRepository {
  EvaluationModelsRepositoryImpl(this._datasource);

  final EvaluationModelsDatasource _datasource;

  @override
  Future<List<EvaluationModel>> list({bool includeInactive = true}) =>
      _datasource.list(includeInactive: includeInactive);

  @override
  Future<EvaluationModel> getById(String id) => _datasource.getById(id);

  @override
  Future<EvaluationModel> create({
    required String name,
    String? description,
    List<({String name, double maxScore})>? items,
  }) =>
      _datasource.create(name: name, description: description, items: items);

  @override
  Future<EvaluationModel> update(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  }) =>
      _datasource.update(id, name: name, description: description, isActive: isActive);

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<EvaluationModel> deactivate(String id) => _datasource.deactivate(id);

  @override
  Future<EvaluationModelItem> createItem(
    String modelId, {
    required String name,
    required double maxScore,
    bool isRecovery = false,
    String? recoversItemId,
  }) =>
      _datasource.createItem(
        modelId,
        name: name,
        maxScore: maxScore,
        isRecovery: isRecovery,
        recoversItemId: recoversItemId,
      );

  @override
  Future<EvaluationModelItem> updateItem(
    String modelId,
    String itemId, {
    String? name,
    double? maxScore,
    bool? isRecovery,
    String? recoversItemId,
  }) =>
      _datasource.updateItem(
        modelId,
        itemId,
        name: name,
        maxScore: maxScore,
        isRecovery: isRecovery,
        recoversItemId: recoversItemId,
      );

  @override
  Future<void> deleteItem(String modelId, String itemId) =>
      _datasource.deleteItem(modelId, itemId);

  @override
  Future<EvaluationModel> reorderItems(String modelId, List<String> itemIds) =>
      _datasource.reorderItems(modelId, itemIds);
}
