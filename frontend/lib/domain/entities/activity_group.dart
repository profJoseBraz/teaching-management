class ActivityGroup {
  const ActivityGroup({
    required this.id,
    required this.activityId,
    required this.name,
    required this.studentIds,
  });

  final String id;
  final String activityId;
  final String name;
  final List<String> studentIds;
}
