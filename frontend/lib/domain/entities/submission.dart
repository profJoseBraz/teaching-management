class Submission {
  const Submission({
    required this.id,
    required this.activityId,
    required this.studentId,
    this.groupId,
    required this.status,
    this.score,
    this.observations,
    this.studentName,
  });

  final String id;
  final String activityId;
  final String studentId;
  final String? groupId;
  final String status;
  final double? score;
  final String? observations;

  /// Preenchido pela tela ao cruzar com a lista de matrículas da turma.
  final String? studentName;

  bool get isGraded => status == 'GRADED';

  Submission copyWithStudentName(String? name) => Submission(
        id: id,
        activityId: activityId,
        studentId: studentId,
        groupId: groupId,
        status: status,
        score: score,
        observations: observations,
        studentName: name ?? studentName,
      );
}
