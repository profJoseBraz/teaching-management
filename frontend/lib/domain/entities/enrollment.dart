import 'student.dart';

class Enrollment {
  const Enrollment({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.status,
    this.student,
  });

  final String id;
  final String classId;
  final String studentId;
  final String status;
  final Student? student;

  bool get isActive => status == 'ACTIVE';
}
