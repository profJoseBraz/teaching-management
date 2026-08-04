import 'student.dart';

enum StudentPasteCandidateStatus { existing, isNew }

class StudentPasteCandidate {
  const StudentPasteCandidate({
    required this.key,
    required this.lineNumber,
    required this.line,
    required this.name,
    this.registryCode,
    this.email,
    this.phone,
    this.notes,
    required this.status,
    this.student,
  });

  final String key;
  final int lineNumber;
  final String line;
  final String name;
  final String? registryCode;
  final String? email;
  final String? phone;
  final String? notes;
  final StudentPasteCandidateStatus status;
  final Student? student;

  bool get isExisting => status == StudentPasteCandidateStatus.existing;
  bool get isNew => status == StudentPasteCandidateStatus.isNew;
}

class StudentPasteSkippedRow {
  const StudentPasteSkippedRow({
    required this.lineNumber,
    required this.line,
    required this.reason,
  });

  final int lineNumber;
  final String line;
  final String reason;
}

class StudentPastePreview {
  const StudentPastePreview({
    required this.candidates,
    required this.skipped,
    required this.totalParsed,
    required this.totalExisting,
    required this.totalNew,
  });

  final List<StudentPasteCandidate> candidates;
  final List<StudentPasteSkippedRow> skipped;
  final int totalParsed;
  final int totalExisting;
  final int totalNew;
}
