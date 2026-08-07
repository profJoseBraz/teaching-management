import '../../core/network/api_client.dart';
import '../../domain/entities/evaluation_model.dart';

EvaluationModelItem evaluationModelItemFromJson(Map<String, dynamic> json) => EvaluationModelItem(
      id: json['id'] as String,
      evaluationModelId: json['evaluationModelId'] as String,
      name: json['name'] as String,
      maxScore: (json['maxScore'] as num).toDouble(),
      sortOrder: json['sortOrder'] as int? ?? 0,
      isRecovery: json['isRecovery'] as bool? ?? false,
      recoversItemId: json['recoversItemId'] as String?,
    );

EvaluationModel evaluationModelFromJson(Map<String, dynamic> json) => EvaluationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .map((e) => evaluationModelItemFromJson(e as Map<String, dynamic>))
          .toList(),
    );

class EvaluationModelsDatasource {
  EvaluationModelsDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<EvaluationModel>> list({bool includeInactive = true}) async {
    final response = await _apiClient.get(
      '/evaluation-models',
      query: {'includeInactive': includeInactive.toString()},
    );
    return (response['data'] as List)
        .map((e) => evaluationModelFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EvaluationModel> getById(String id) async {
    final response = await _apiClient.get('/evaluation-models/$id');
    return evaluationModelFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<EvaluationModel> create({
    required String name,
    String? description,
    List<({String name, double maxScore})>? items,
  }) async {
    final response = await _apiClient.post('/evaluation-models', data: {
      'name': name,
      if (description != null) 'description': description,
      if (items != null)
        'items': [
          for (var i = 0; i < items.length; i++)
            {
              'name': items[i].name,
              'maxScore': items[i].maxScore,
              'sortOrder': i,
            },
        ],
    });
    return evaluationModelFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<EvaluationModel> update(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final response = await _apiClient.patch('/evaluation-models/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isActive != null) 'isActive': isActive,
    });
    return evaluationModelFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/evaluation-models/$id');
  }

  Future<EvaluationModel> deactivate(String id) async {
    final response = await _apiClient.post('/evaluation-models/$id/deactivate');
    return evaluationModelFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<EvaluationModelItem> createItem(
    String modelId, {
    required String name,
    required double maxScore,
    bool isRecovery = false,
    String? recoversItemId,
  }) async {
    final response = await _apiClient.post('/evaluation-models/$modelId/items', data: {
      'name': name,
      'maxScore': maxScore,
      'isRecovery': isRecovery,
      if (isRecovery) 'recoversItemId': recoversItemId,
    });
    return evaluationModelItemFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<EvaluationModelItem> updateItem(
    String modelId,
    String itemId, {
    String? name,
    double? maxScore,
    bool? isRecovery,
    String? recoversItemId,
  }) async {
    final response = await _apiClient.patch(
      '/evaluation-models/$modelId/items/$itemId',
      data: {
        if (name != null) 'name': name,
        if (maxScore != null) 'maxScore': maxScore,
        if (isRecovery != null) 'isRecovery': isRecovery,
        if (isRecovery == false)
          'recoversItemId': null
        else if (recoversItemId != null)
          'recoversItemId': recoversItemId,
      },
    );
    return evaluationModelItemFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteItem(String modelId, String itemId) async {
    await _apiClient.delete('/evaluation-models/$modelId/items/$itemId');
  }

  Future<EvaluationModel> reorderItems(String modelId, List<String> itemIds) async {
    final response = await _apiClient.put(
      '/evaluation-models/$modelId/items/reorder',
      data: {'itemIds': itemIds},
    );
    return evaluationModelFromJson(response['data'] as Map<String, dynamic>);
  }
}
