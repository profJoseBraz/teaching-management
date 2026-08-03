import type { AcademicYear as PrismaAcademicYear } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { AcademicYear } from '../domain/academic-year';
import type {
  AcademicYearRepository,
  CreateAcademicYearInput,
  UpdateAcademicYearInput,
} from '../application/ports/academic-year-repository';

function mapAcademicYear(row: PrismaAcademicYear): AcademicYear {
  return {
    id: row.id,
    teacherId: row.teacherId,
    year: row.year,
    label: row.label,
    isCurrent: row.isCurrent,
    startsOn: row.startsOn,
    endsOn: row.endsOn,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaAcademicYearRepository implements AcademicYearRepository {
  async create(input: CreateAcademicYearInput): Promise<AcademicYear> {
    const row = await prisma.academicYear.create({
      data: {
        teacherId: input.teacherId,
        year: input.year,
        label: input.label ?? null,
        startsOn: input.startsOn ?? null,
        endsOn: input.endsOn ?? null,
      },
    });
    return mapAcademicYear(row);
  }

  async findById(teacherId: string, id: string): Promise<AcademicYear | null> {
    const row = await prisma.academicYear.findFirst({ where: { id, teacherId } });
    return row ? mapAcademicYear(row) : null;
  }

  async findByYear(teacherId: string, year: number): Promise<AcademicYear | null> {
    const row = await prisma.academicYear.findFirst({ where: { teacherId, year } });
    return row ? mapAcademicYear(row) : null;
  }

  async list(teacherId: string): Promise<AcademicYear[]> {
    const rows = await prisma.academicYear.findMany({
      where: { teacherId, deletedAt: null },
      orderBy: { year: 'desc' },
    });
    return rows.map(mapAcademicYear);
  }

  async update(teacherId: string, id: string, input: UpdateAcademicYearInput): Promise<AcademicYear> {
    await prisma.academicYear.updateMany({
      where: { id, teacherId },
      data: {
        ...(input.label !== undefined ? { label: input.label } : {}),
        ...(input.startsOn !== undefined ? { startsOn: input.startsOn } : {}),
        ...(input.endsOn !== undefined ? { endsOn: input.endsOn } : {}),
      },
    });
    const row = await prisma.academicYear.findFirstOrThrow({ where: { id, teacherId } });
    return mapAcademicYear(row);
  }

  async setCurrent(teacherId: string, id: string): Promise<AcademicYear> {
    await prisma.$transaction([
      prisma.academicYear.updateMany({
        where: { teacherId, isCurrent: true, NOT: { id } },
        data: { isCurrent: false },
      }),
      prisma.academicYear.updateMany({
        where: { id, teacherId },
        data: { isCurrent: true },
      }),
    ]);
    const row = await prisma.academicYear.findFirstOrThrow({ where: { id, teacherId } });
    return mapAcademicYear(row);
  }
}
