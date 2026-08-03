class AttentionItem {
  const AttentionItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.count,
    this.actionRoute,
    this.filters = const {},
  });

  final String id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final int count;
  final String? actionRoute;
  final Map<String, dynamic> filters;
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalAttentionItems,
    required this.totalPendingActions,
    required this.bySeverity,
  });

  final int totalAttentionItems;
  final int totalPendingActions;
  final Map<String, int> bySeverity;
}

class DashboardResponse {
  const DashboardResponse({required this.attentionItems, required this.summary});

  final List<AttentionItem> attentionItems;
  final DashboardSummary summary;
}
