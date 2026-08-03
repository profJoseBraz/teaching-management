import 'discipline.dart';

class CourseDiscipline {
  const CourseDiscipline({
    required this.id,
    required this.courseId,
    required this.disciplineId,
    this.discipline,
  });

  final String id;
  final String courseId;
  final String disciplineId;
  final Discipline? discipline;
}
