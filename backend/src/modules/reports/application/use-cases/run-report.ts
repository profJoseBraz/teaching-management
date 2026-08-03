import { ValidationError } from '../../../../shared/domain/errors';
import type { ReportFilters, ReportResult, ReportRow, ReportType } from '../../domain/report';
import type { ReportsRepository } from '../ports/reports-repository';

export type RunReportInput = {
  teacherId: string;
  reportType: ReportType;
  filters: ReportFilters;
};

type ReportHandler = (teacherId: string, filters: ReportFilters) => Promise<ReportRow[]>;

/** Único ponto de entrada para todos os relatórios filtráveis — despacha por `reportType`. */
export class RunReportUseCase {
  private readonly handlers: Record<ReportType, ReportHandler>;

  constructor(private readonly reports: ReportsRepository) {
    this.handlers = {
      'excess-absences': (teacherId, filters) => this.reports.getExcessAbsences(teacherId, filters),
      'pending-activities': (teacherId, filters) => this.reports.getPendingActivities(teacherId, filters),
      'ungraded-activities': (teacherId, filters) => this.reports.getUngradedActivities(teacherId, filters),
      'contents-in-progress': (teacherId, filters) => this.reports.getContentsInProgress(teacherId, filters),
      'lessons-without-attendance': (teacherId, filters) =>
        this.reports.getLessonsWithoutAttendance(teacherId, filters),
      'absence-vs-non-submission': (teacherId, filters) =>
        this.reports.getAbsenceVsNonSubmission(teacherId, filters),
      'attendance-percentage': (teacherId, filters) => this.reports.getAttendancePercentage(teacherId, filters),
      'class-average': (teacherId, filters) => this.reports.getClassAverage(teacherId, filters),
      'grades-by-student': (teacherId, filters) => this.reports.getGradesByStudent(teacherId, filters),
      'attendance-by-student': (teacherId, filters) => this.reports.getAttendanceByStudent(teacherId, filters),
      'submission-status': (teacherId, filters) => this.reports.getSubmissionStatus(teacherId, filters),
      'lessons-taught': (teacherId, filters) => this.reports.getLessonsTaught(teacherId, filters),
      'students-without-grade': (teacherId, filters) => this.reports.getStudentsWithoutGrade(teacherId, filters),
      'average-by-activity': (teacherId, filters) => this.reports.getAverageByActivity(teacherId, filters),
    };
  }

  async execute(input: RunReportInput): Promise<ReportResult> {
    const handler = this.handlers[input.reportType];
    if (!handler) {
      throw new ValidationError(`Unsupported report type: ${input.reportType}`);
    }

    const rows = await handler(input.teacherId, input.filters);

    return {
      reportType: input.reportType,
      filters: input.filters,
      generatedAt: new Date(),
      rows,
      totalRows: rows.length,
    };
  }
}
