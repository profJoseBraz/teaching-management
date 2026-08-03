export type InsightsScopeFilters = {
  teacherId: string;
  academicYearId?: string;
  classId?: string;
};

/**
 * Porta de leitura do Insights Engine. Cada método corresponde a um cruzamento
 * descrito em docs/ARCHITECTURE.md §7 (Insights) / §9 (Insights Engine) e retorna
 * apenas a contagem necessária para compor um `AttentionItem` — sem materializar
 * as linhas, conforme decisão arquitetural registrada no documento.
 */
export interface InsightsRepository {
  countLessonsWithoutAttendance(filters: InsightsScopeFilters): Promise<number>;
  countOverdueUngradedActivities(filters: InsightsScopeFilters): Promise<number>;
  countSubmissionsAwaitingGrade(filters: InsightsScopeFilters): Promise<number>;
  countContentsInProgress(filters: InsightsScopeFilters): Promise<number>;
  countStudentsPendingSubmission(filters: InsightsScopeFilters): Promise<number>;
  countAbsentOnActivityLesson(filters: InsightsScopeFilters): Promise<number>;
  countStudentsWithExcessAbsences(filters: InsightsScopeFilters, threshold: number): Promise<number>;
  countActivitiesWithoutScore(filters: InsightsScopeFilters): Promise<number>;
}
