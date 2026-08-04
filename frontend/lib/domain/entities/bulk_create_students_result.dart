import 'student.dart';

class BulkCreateSkippedRow {
  const BulkCreateSkippedRow({
    required this.lineNumber,
    required this.line,
    required this.reason,
  });

  final int lineNumber;
  final String line;
  final String reason;
}

class BulkCreateStudentsResult {
  const BulkCreateStudentsResult({
    required this.created,
    required this.skipped,
    required this.totalParsed,
    required this.totalCreated,
  });

  final List<Student> created;
  final List<BulkCreateSkippedRow> skipped;
  final int totalParsed;
  final int totalCreated;
}
