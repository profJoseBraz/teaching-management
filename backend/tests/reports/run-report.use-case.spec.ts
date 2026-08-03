import { describe, expect, it, vi } from 'vitest';
import { ValidationError } from '../../src/shared/domain/errors';
import { RunReportUseCase } from '../../src/modules/reports/application/use-cases/run-report';
import type { ReportsRepository } from '../../src/modules/reports/application/ports/reports-repository';
import type { ReportType } from '../../src/modules/reports/domain/report';
import { REPORT_TYPES } from '../../src/modules/reports/domain/report';

function buildReportsRepository(overrides: Partial<ReportsRepository> = {}): ReportsRepository {
  return {
    getExcessAbsences: vi.fn().mockResolvedValue([]),
    getPendingActivities: vi.fn().mockResolvedValue([]),
    getUngradedActivities: vi.fn().mockResolvedValue([]),
    getContentsInProgress: vi.fn().mockResolvedValue([]),
    getLessonsWithoutAttendance: vi.fn().mockResolvedValue([]),
    getAbsenceVsNonSubmission: vi.fn().mockResolvedValue([]),
    getAttendancePercentage: vi.fn().mockResolvedValue([]),
    getClassAverage: vi.fn().mockResolvedValue([]),
    getGradesByStudent: vi.fn().mockResolvedValue([]),
    getAttendanceByStudent: vi.fn().mockResolvedValue([]),
    getSubmissionStatus: vi.fn().mockResolvedValue([]),
    getLessonsTaught: vi.fn().mockResolvedValue([]),
    getStudentsWithoutGrade: vi.fn().mockResolvedValue([]),
    getAverageByActivity: vi.fn().mockResolvedValue([]),
    ...overrides,
  };
}

describe('RunReportUseCase', () => {
  it('dispatches to the repository method matching the requested report type', async () => {
    const rows = [{ studentId: 's1', absenceCount: 7 }];
    const reports = buildReportsRepository({ getExcessAbsences: vi.fn().mockResolvedValue(rows) });
    const useCase = new RunReportUseCase(reports);

    const result = await useCase.execute({
      teacherId: 'teacher-1',
      reportType: 'excess-absences',
      filters: { classId: 'class-1' },
    });

    expect(reports.getExcessAbsences).toHaveBeenCalledWith('teacher-1', { classId: 'class-1' });
    expect(result.rows).toEqual(rows);
    expect(result.totalRows).toBe(1);
    expect(result.reportType).toBe('excess-absences');
    expect(result.generatedAt).toBeInstanceOf(Date);
  });

  it('has a handler registered for every declared report type', async () => {
    const reports = buildReportsRepository();
    const useCase = new RunReportUseCase(reports);

    for (const reportType of REPORT_TYPES) {
      await expect(
        useCase.execute({ teacherId: 'teacher-1', reportType, filters: {} }),
      ).resolves.toMatchObject({ reportType, rows: [], totalRows: 0 });
    }
  });

  it('rejects an unsupported report type', async () => {
    const useCase = new RunReportUseCase(buildReportsRepository());

    await expect(
      useCase.execute({
        teacherId: 'teacher-1',
        reportType: 'not-a-real-report' as ReportType,
        filters: {},
      }),
    ).rejects.toBeInstanceOf(ValidationError);
  });
});
