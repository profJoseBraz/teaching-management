import '../entities/attention_item.dart';

abstract interface class DashboardRepository {
  Future<DashboardResponse> getDashboard({String? academicYearId, String? classId});
  Future<List<AttentionItem>> getAttentionItems({String? academicYearId, String? classId});
}
