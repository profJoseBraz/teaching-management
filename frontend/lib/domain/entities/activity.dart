class Activity {
  const Activity({
    required this.id,
    required this.classId,
    required this.disciplineId,
    this.originLessonId,
    this.assessmentPeriodId,
    required this.title,
    this.description,
    this.tag,
    required this.category,
    required this.mode,
    required this.gradeMode,
    required this.maxScore,
    required this.createdOn,
    required this.dueDate,
  });

  final String id;
  final String classId;
  final String disciplineId;
  final String? originLessonId;
  final String? assessmentPeriodId;
  final String title;
  final String? description;
  /// Rótulo livre opcional para agrupar atividades.
  final String? tag;
  final String category;
  final String mode;
  final String gradeMode;
  final double maxScore;
  final DateTime createdOn;
  final DateTime dueDate;

  bool get isGroup => mode == 'GROUP';
  bool get isSharedGrade => gradeMode == 'SHARED';
  bool get isOverdue => dueDate.isBefore(DateTime.now());

  static const categoryLabels = {
    'EXERCISE': 'Exercício',
    'ASSIGNMENT': 'Trabalho',
    'PROJECT': 'Projeto',
    'RESEARCH': 'Pesquisa',
    'SEMINAR': 'Seminário',
    'EXAM': 'Prova',
    'OTHER': 'Outro',
  };

  String get categoryLabel => categoryLabels[category] ?? category;
}
