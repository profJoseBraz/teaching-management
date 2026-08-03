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
}
