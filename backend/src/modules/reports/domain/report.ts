/** Catálogo de relatórios — docs/ARCHITECTURE.md §17 (P0 + P1 "se direto"). */
export const REPORT_TYPES = [
  // P0
  'excess-absences',
  'pending-activities',
  'ungraded-activities',
  'contents-in-progress',
  'lessons-without-attendance',
  'absence-vs-non-submission',
  // P1
  'attendance-percentage',
  'class-average',
  'grades-by-student',
  'attendance-by-student',
  'submission-status',
  'lessons-taught',
  'students-without-grade',
  'average-by-activity',
] as const;

export type ReportType = (typeof REPORT_TYPES)[number];

/** Filtros comuns a todos os relatórios — docs/ARCHITECTURE.md §8 ("Todos os relatórios aceitam..."). */
export type ReportFilters = {
  academicYearId?: string;
  courseId?: string;
  disciplineId?: string;
  classId?: string;
  assessmentPeriodId?: string;
  from?: Date;
  to?: Date;
  /** Usado apenas por `excess-absences`; default aplicado no repositório. */
  threshold?: number;
};

export type ReportRow = Record<string, unknown>;

export type ReportResult = {
  reportType: ReportType;
  filters: ReportFilters;
  generatedAt: Date;
  rows: ReportRow[];
  totalRows: number;
};
