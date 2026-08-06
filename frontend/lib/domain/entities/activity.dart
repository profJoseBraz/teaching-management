class Activity {
  const Activity({
    required this.id,
    required this.classId,
    required this.disciplineIds,
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
    this.evaluated = false,
    this.evaluatedAt,
  });

  final String id;
  final String classId;
  /// Disciplinas vinculadas (N:N). Mín. 1.
  final List<String> disciplineIds;
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
  /// Professor confirma que a avaliação da atividade foi encerrada.
  final bool evaluated;
  final DateTime? evaluatedAt;

  bool get isGroup => mode == 'GROUP';
  bool get isSharedGrade => gradeMode == 'SHARED';
  bool get isOverdue => !evaluated && dueDate.isBefore(DateTime.now());

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

  /// Nomes das disciplinas para exibição, na ordem de [disciplineIds].
  String disciplineNamesLabel(Map<String, String> namesById) {
    if (disciplineIds.isEmpty) return 'Disciplina';
    return disciplineIds.map((id) => namesById[id] ?? 'Disciplina').join(', ');
  }

  Activity copyWith({bool? evaluated, DateTime? evaluatedAt}) => Activity(
        id: id,
        classId: classId,
        disciplineIds: disciplineIds,
        originLessonId: originLessonId,
        assessmentPeriodId: assessmentPeriodId,
        title: title,
        description: description,
        tag: tag,
        category: category,
        mode: mode,
        gradeMode: gradeMode,
        maxScore: maxScore,
        createdOn: createdOn,
        dueDate: dueDate,
        evaluated: evaluated ?? this.evaluated,
        evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      );
}
