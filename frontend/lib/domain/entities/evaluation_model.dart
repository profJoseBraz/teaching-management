class EvaluationModelItem {
  const EvaluationModelItem({
    required this.id,
    required this.evaluationModelId,
    required this.name,
    required this.maxScore,
    required this.sortOrder,
    this.isRecovery = false,
    this.recoversItemId,
  });

  final String id;
  final String evaluationModelId;
  final String name;
  final double maxScore;
  final int sortOrder;
  final bool isRecovery;
  final String? recoversItemId;
}

class EvaluationModel {
  const EvaluationModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.sortOrder,
    required this.items,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final int sortOrder;
  final List<EvaluationModelItem> items;
}
