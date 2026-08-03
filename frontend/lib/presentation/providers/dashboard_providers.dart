import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/attention_item.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'academic_providers.dart';
import 'session_providers.dart';

final dashboardDatasourceProvider = Provider<DashboardDatasource>(
  (ref) => DashboardDatasource(ref.watch(apiClientProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(dashboardDatasourceProvider)),
);

/// Dashboard (pendências + resumo) filtrado pelo ano letivo efetivo.
final dashboardProvider = FutureProvider<DashboardResponse>((ref) {
  final yearId = ref.watch(effectiveAcademicYearIdProvider);
  return ref.watch(dashboardRepositoryProvider).getDashboard(academicYearId: yearId);
});
