import 'activity.dart';
import 'submission.dart';

class ActivitySummary {
  const ActivitySummary({
    required this.total,
    required this.pending,
    required this.submitted,
    required this.graded,
    this.averageScore,
  });

  final int total;
  final int pending;
  final int submitted;
  final int graded;
  final double? averageScore;

  factory ActivitySummary.fromSubmissions(List<Submission> submissions) {
    final gradedScores = submissions
        .where((s) => s.status == 'GRADED' && s.score != null)
        .map((s) => s.score!)
        .toList();

    return ActivitySummary(
      total: submissions.length,
      pending: submissions.where((s) => s.status == 'PENDING').length,
      submitted: submissions.where((s) => s.status == 'SUBMITTED').length,
      graded: submissions.where((s) => s.status == 'GRADED').length,
      averageScore: gradedScores.isEmpty
          ? null
          : gradedScores.reduce((a, b) => a + b) / gradedScores.length,
    );
  }
}

class ActivityDetail {
  const ActivityDetail({
    required this.activity,
    required this.submissions,
    required this.summary,
  });

  final Activity activity;
  final List<Submission> submissions;
  final ActivitySummary summary;

  /// Atualiza entregas no cliente sem novo GET (evita tempestade de requests).
  ActivityDetail withUpdatedSubmissions(Iterable<Submission> updates) {
    final byId = {for (final s in updates) s.id: s};
    final next = submissions.map((s) => byId[s.id] ?? s).toList();
    return ActivityDetail(
      activity: activity,
      submissions: next,
      summary: ActivitySummary.fromSubmissions(next),
    );
  }
}
