/// Referência leve a uma disciplina vinculada a uma turma, no formato
/// `{ id, name }` devolvido embutido nas respostas de `Class` pela API.
class ClassDisciplineRef {
  const ClassDisciplineRef({required this.id, required this.name});

  final String id;
  final String name;
}

/// Representa uma turma (`Class` na API). Renomeada para `SchoolClass` para
/// evitar conflito com a palavra reservada `class` do Dart.
///
/// Uma turma pode ministrar múltiplas disciplinas simultaneamente
/// (`disciplineIds`/`disciplines`), refletindo o vínculo N:N do backend.
class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.academicYearId,
    required this.courseId,
    required this.disciplineIds,
    required this.disciplines,
    required this.name,
    this.shift,
    required this.status,
    this.courseName,
  });

  final String id;
  final String academicYearId;
  final String courseId;
  final List<String> disciplineIds;
  final List<ClassDisciplineRef> disciplines;
  final String name;
  final String? shift;
  final String status;

  /// Preenchido pela tela ao cruzar com a lista de cursos já carregada,
  /// evitando N chamadas extras à API.
  final String? courseName;

  bool get isActive => status == 'ACTIVE';

  /// Nomes das disciplinas vinculadas, já formatados para exibição em UI.
  String get disciplinesLabel => disciplines.isEmpty ? '—' : disciplines.map((d) => d.name).join(', ');

  String get shiftLabel {
    switch (shift) {
      case 'MORNING':
        return 'Manhã';
      case 'AFTERNOON':
        return 'Tarde';
      case 'EVENING':
        return 'Vespertino';
      case 'NIGHT':
        return 'Noite';
      default:
        return '—';
    }
  }

  SchoolClass copyWithLookup({String? courseName}) => SchoolClass(
        id: id,
        academicYearId: academicYearId,
        courseId: courseId,
        disciplineIds: disciplineIds,
        disciplines: disciplines,
        name: name,
        shift: shift,
        status: status,
        courseName: courseName ?? this.courseName,
      );
}
