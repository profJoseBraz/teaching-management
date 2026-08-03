import { describe, expect, it, vi } from 'vitest';
import {
  EXCESS_ABSENCES_THRESHOLD,
  GetAttentionItemsUseCase,
} from '../../src/modules/insights/application/use-cases/get-attention-items';
import type { InsightsRepository } from '../../src/modules/insights/application/ports/insights-repository';

function buildInsightsRepository(overrides: Partial<InsightsRepository> = {}): InsightsRepository {
  return {
    countLessonsWithoutAttendance: vi.fn().mockResolvedValue(0),
    countOverdueUngradedActivities: vi.fn().mockResolvedValue(0),
    countSubmissionsAwaitingGrade: vi.fn().mockResolvedValue(0),
    countContentsInProgress: vi.fn().mockResolvedValue(0),
    countStudentsPendingSubmission: vi.fn().mockResolvedValue(0),
    countAbsentOnActivityLesson: vi.fn().mockResolvedValue(0),
    countStudentsWithExcessAbsences: vi.fn().mockResolvedValue(0),
    countActivitiesWithoutScore: vi.fn().mockResolvedValue(0),
    ...overrides,
  };
}

describe('GetAttentionItemsUseCase', () => {
  it('returns an empty list when there is nothing pending', async () => {
    const useCase = new GetAttentionItemsUseCase(buildInsightsRepository());

    const result = await useCase.execute({ teacherId: 'teacher-1' });

    expect(result).toEqual([]);
  });

  it('omits types with zero count and sorts by severity then count desc', async () => {
    const insights = buildInsightsRepository({
      countLessonsWithoutAttendance: vi.fn().mockResolvedValue(0),
      countOverdueUngradedActivities: vi.fn().mockResolvedValue(2),
      countSubmissionsAwaitingGrade: vi.fn().mockResolvedValue(10),
      countContentsInProgress: vi.fn().mockResolvedValue(3),
      countStudentsWithExcessAbsences: vi.fn().mockResolvedValue(1),
    });

    const useCase = new GetAttentionItemsUseCase(insights);
    const result = await useCase.execute({ teacherId: 'teacher-1' });

    expect(result.map((item) => item.type)).toEqual([
      'ACTIVITIES_AWAITING_GRADE',
      'OVERDUE_UNGRADED_ACTIVITIES',
      'EXCESS_ABSENCES',
      'CONTENTS_IN_PROGRESS',
    ]);
    expect(result.every((item) => item.count > 0)).toBe(true);
  });

  it('forwards scope filters to the repository and to each attention item', async () => {
    const insights = buildInsightsRepository({
      countContentsInProgress: vi.fn().mockResolvedValue(1),
    });
    const useCase = new GetAttentionItemsUseCase(insights);

    const result = await useCase.execute({
      teacherId: 'teacher-1',
      academicYearId: 'year-1',
      classId: 'class-1',
    });

    expect(insights.countContentsInProgress).toHaveBeenCalledWith({
      teacherId: 'teacher-1',
      academicYearId: 'year-1',
      classId: 'class-1',
    });
    expect(result[0]!.filters).toEqual({ academicYearId: 'year-1', classId: 'class-1' });
  });

  it('applies the excess absences threshold from the shared constant', async () => {
    const insights = buildInsightsRepository();
    const useCase = new GetAttentionItemsUseCase(insights);

    await useCase.execute({ teacherId: 'teacher-1' });

    expect(insights.countStudentsWithExcessAbsences).toHaveBeenCalledWith(
      { teacherId: 'teacher-1', academicYearId: undefined, classId: undefined },
      EXCESS_ABSENCES_THRESHOLD,
    );
  });
});
