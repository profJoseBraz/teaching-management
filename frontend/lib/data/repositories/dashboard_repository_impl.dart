import '../../domain/entities/attention_item.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._datasource);

  final DashboardDatasource _datasource;

  @override
  Future<DashboardResponse> getDashboard({String? academicYearId, String? classId}) =>
      _datasource.getDashboard(academicYearId: academicYearId, classId: classId);

  @override
  Future<List<AttentionItem>> getAttentionItems({String? academicYearId, String? classId}) =>
      _datasource.getAttentionItems(academicYearId: academicYearId, classId: classId);
}
