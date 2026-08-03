class Lesson {
  const Lesson({
    required this.id,
    required this.classId,
    required this.disciplineId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.observations,
    required this.attendanceCompleted,
  });

  final String id;
  final String classId;
  final String disciplineId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String? observations;
  final bool attendanceCompleted;

  bool get isPast => date.isBefore(DateTime.now().copyWith(hour: 23, minute: 59));
}
