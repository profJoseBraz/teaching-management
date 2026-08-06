class AgendaNote {
  const AgendaNote({
    required this.id,
    required this.date,
    required this.content,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final String content;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Filtro de status na listagem da agenda.
enum AgendaCompletionFilter {
  all,
  pending,
  completed,
}
