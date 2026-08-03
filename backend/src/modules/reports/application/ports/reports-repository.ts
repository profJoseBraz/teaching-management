import type { ReportFilters, ReportRow } from '../../domain/report';

/**
 * Porta de leitura dos relatórios. Um método por tipo de relatório — cada um
 * corresponde a uma query otimizada, sem materializar dados desnecessários
 * (docs/ARCHITECTURE.md, tabela de decisões arquiteturais).
 */
export interface ReportsRepository {
  getExcessAbsences(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getPendingActivities(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getUngradedActivities(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getContentsInProgress(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getLessonsWithoutAttendance(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getAbsenceVsNonSubmission(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getAttendancePercentage(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getClassAverage(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getGradesByStudent(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getAttendanceByStudent(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getSubmissionStatus(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getLessonsTaught(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getStudentsWithoutGrade(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
  getAverageByActivity(teacherId: string, filters: ReportFilters): Promise<ReportRow[]>;
}
