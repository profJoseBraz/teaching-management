/// Conteúdo pedagógico de uma turma (`Content` na API). Renomeado para
/// `ContentItem` para evitar ambiguidade com `Widget.content` e afins.
class ContentItem {
  const ContentItem({
    required this.id,
    required this.classId,
    required this.disciplineId,
    this.assessmentPeriodId,
    required this.title,
    this.description,
    required this.status,
    required this.startedAt,
    this.completedAt,
  });

  final String id;
  final String classId;
  final String disciplineId;
  final String? assessmentPeriodId;
  final String title;
  final String? description;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;

  bool get isCompleted => status == 'COMPLETED';
}
