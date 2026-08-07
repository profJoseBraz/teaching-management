import '../entities/evaluation_model.dart';

abstract interface class EvaluationModelsRepository {
  Future<List<EvaluationModel>> list({bool includeInactive = true});
  Future<EvaluationModel> getById(String id);
  Future<EvaluationModel> create({
    required String name,
    String? description,
    List<({String name, double maxScore})>? items,
  });
  Future<EvaluationModel> update(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  });
  Future<void> delete(String id);
  Future<EvaluationModel> deactivate(String id);
  Future<EvaluationModelItem> createItem(
    String modelId, {
    required String name,
    required double maxScore,
    bool isRecovery = false,
    String? recoversItemId,
  });
  Future<EvaluationModelItem> updateItem(
    String modelId,
    String itemId, {
    String? name,
    double? maxScore,
    bool? isRecovery,
    String? recoversItemId,
  });
  Future<void> deleteItem(String modelId, String itemId);
  Future<EvaluationModel> reorderItems(String modelId, List<String> itemIds);
}
