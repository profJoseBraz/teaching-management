export const ATTENTION_TYPES = [
  'LESSONS_WITHOUT_ATTENDANCE',
  'OVERDUE_UNGRADED_ACTIVITIES',
  'ACTIVITIES_AWAITING_GRADE',
  'CONTENTS_IN_PROGRESS',
  'STUDENTS_PENDING_SUBMISSION',
  'ABSENT_ON_ACTIVITY_LESSON',
  'EXCESS_ABSENCES',
  'ACTIVITIES_WITHOUT_SCORE',
] as const;

export type AttentionType = (typeof ATTENTION_TYPES)[number];

export const ATTENTION_SEVERITIES = ['high', 'medium', 'low'] as const;

export type AttentionSeverity = (typeof ATTENTION_SEVERITIES)[number];

export type AttentionItemFilters = {
  academicYearId?: string;
  classId?: string;
} & Record<string, unknown>;

/** Pendência acionável do Dashboard — ver docs/ARCHITECTURE.md §9 (Insights Engine). */
export type AttentionItem = {
  id: string;
  type: AttentionType;
  severity: AttentionSeverity;
  title: string;
  message: string;
  count: number;
  actionRoute: string;
  filters: AttentionItemFilters;
};
