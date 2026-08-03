import '../entities/report_result.dart';

abstract interface class ReportsRepository {
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
  });
}
