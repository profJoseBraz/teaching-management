import { describe, expect, it, vi } from 'vitest';
import { ConflictError } from '../../src/shared/domain/errors';
import { CreateAcademicYearUseCase } from '../../src/modules/academic/application/use-cases/create-academic-year';
import type { AcademicYear } from '../../src/modules/academic/domain/academic-year';
import type { AcademicYearRepository } from '../../src/modules/academic/application/ports/academic-year-repository';

function buildAcademicYear(overrides: Partial<AcademicYear> = {}): AcademicYear {
  return {
    id: '11111111-1111-1111-1111-111111111111',
    teacherId: 'teacher-1',
    year: 2026,
    label: null,
    isCurrent: false,
    startsOn: null,
    endsOn: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    deletedAt: null,
    ...overrides,
  };
}

function buildRepository(overrides: Partial<AcademicYearRepository> = {}): AcademicYearRepository {
  return {
    create: vi.fn(),
    findById: vi.fn(),
    findByYear: vi.fn(),
    list: vi.fn(),
    update: vi.fn(),
    setCurrent: vi.fn(),
    ...overrides,
  };
}

describe('CreateAcademicYearUseCase', () => {
  it('creates the academic year when the year is not yet used by the teacher', async () => {
    const created = buildAcademicYear();
    const academicYears = buildRepository({
      findByYear: vi.fn().mockResolvedValue(null),
      create: vi.fn().mockResolvedValue(created),
    });

    const useCase = new CreateAcademicYearUseCase(academicYears);
    const result = await useCase.execute({ teacherId: 'teacher-1', year: 2026 });

    expect(academicYears.findByYear).toHaveBeenCalledWith('teacher-1', 2026);
    expect(academicYears.create).toHaveBeenCalledWith({ teacherId: 'teacher-1', year: 2026 });
    expect(result).toEqual(created);
  });

  it('rejects creating a duplicate year for the same teacher', async () => {
    const academicYears = buildRepository({
      findByYear: vi.fn().mockResolvedValue(buildAcademicYear()),
    });

    const useCase = new CreateAcademicYearUseCase(academicYears);

    await expect(useCase.execute({ teacherId: 'teacher-1', year: 2026 })).rejects.toBeInstanceOf(
      ConflictError,
    );
    expect(academicYears.create).not.toHaveBeenCalled();
  });

  it('allows the same year to be used by different teachers', async () => {
    const created = buildAcademicYear({ teacherId: 'teacher-2' });
    const academicYears = buildRepository({
      findByYear: vi.fn().mockImplementation(async (teacherId: string) => {
        return teacherId === 'teacher-1' ? buildAcademicYear() : null;
      }),
      create: vi.fn().mockResolvedValue(created),
    });

    const useCase = new CreateAcademicYearUseCase(academicYears);
    const result = await useCase.execute({ teacherId: 'teacher-2', year: 2026 });

    expect(result.teacherId).toBe('teacher-2');
    expect(academicYears.create).toHaveBeenCalledWith({ teacherId: 'teacher-2', year: 2026 });
  });
});
