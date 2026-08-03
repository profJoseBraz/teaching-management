import '../../domain/entities/report_result.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._datasource);

  final ReportsDatasource _datasource;

  @override
  Future<ReportResult> runReport(
    String reportType, {
    String? academicYearId,
    String? courseId,
    String? disciplineId,
    String? classId,
    String? assessmentPeriodId,
    DateTime? from,
    DateTime? to,
    int? threshold,
  }) =>
      _datasource.runReport(
        reportType,
        academicYearId: academicYearId,
        courseId: courseId,
        disciplineId: disciplineId,
        classId: classId,
        assessmentPeriodId: assessmentPeriodId,
        from: from,
        to: to,
        threshold: threshold,
      );
}
