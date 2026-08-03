class AssessmentPeriod {
  const AssessmentPeriod({
    required this.id,
    required this.academicYearId,
    this.classId,
    required this.name,
    required this.sortOrder,
    this.startsOn,
    this.endsOn,
  });

  final String id;
  final String academicYearId;
  final String? classId;
  final String name;
  final int sortOrder;
  final DateTime? startsOn;
  final DateTime? endsOn;
}
