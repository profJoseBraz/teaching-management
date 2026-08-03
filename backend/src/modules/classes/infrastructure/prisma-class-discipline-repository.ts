import type { ClassDiscipline as PrismaClassDiscipline } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { ClassDiscipline, ClassDisciplineDetail } from '../domain/class-discipline';
import type {
  ClassDisciplineRepository,
  CreateClassDisciplineInput,
} from '../application/ports/class-discipline-repository';

function mapClassDiscipline(row: PrismaClassDiscipline): ClassDiscipline {
  return {
    id: row.id,
    teacherId: row.teacherId,
    classId: row.classId,
    disciplineId: row.disciplineId,
    createdAt: row.createdAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaClassDisciplineRepository implements ClassDisciplineRepository {
  async findLink(teacherId: string, classId: string, disciplineId: string): Promise<ClassDiscipline | null> {
    const row = await prisma.classDiscipline.findFirst({
      where: { teacherId, classId, disciplineId },
    });
    return row ? mapClassDiscipline(row) : null;
  }

  async create(input: CreateClassDisciplineInput): Promise<ClassDiscipline> {
    const row = await prisma.classDiscipline.create({
      data: {
        teacherId: input.teacherId,
        classId: input.classId,
        disciplineId: input.disciplineId,
      },
    });
    return mapClassDiscipline(row);
  }

  async reactivate(teacherId: string, id: string): Promise<ClassDiscipline> {
    await prisma.classDiscipline.updateMany({
      where: { id, teacherId },
      data: { deletedAt: null },
    });
    const row = await prisma.classDiscipline.findFirstOrThrow({ where: { id, teacherId } });
    return mapClassDiscipline(row);
  }

  async softDeleteLink(teacherId: string, classId: string, disciplineId: string): Promise<void> {
    await prisma.classDiscipline.updateMany({
      where: { teacherId, classId, disciplineId },
      data: { deletedAt: new Date() },
    });
  }

  async listByClass(teacherId: string, classId: string): Promise<ClassDisciplineDetail[]> {
    const rows = await prisma.classDiscipline.findMany({
      where: { teacherId, classId, deletedAt: null },
      include: {
        discipline: { select: { id: true, name: true, description: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    return rows.map((row) => ({
      ...mapClassDiscipline(row),
      discipline: row.discipline,
    }));
  }

  async listActiveByClasses(
    teacherId: string,
    classIds: string[],
  ): Promise<Map<string, ClassDisciplineDetail[]>> {
    const result = new Map<string, ClassDisciplineDetail[]>();
    if (classIds.length === 0) {
      return result;
    }

    const rows = await prisma.classDiscipline.findMany({
      where: { teacherId, classId: { in: classIds }, deletedAt: null },
      include: {
        discipline: { select: { id: true, name: true, description: true } },
      },
      orderBy: { createdAt: 'asc' },
    });

    for (const row of rows) {
      const detail: ClassDisciplineDetail = { ...mapClassDiscipline(row), discipline: row.discipline };
      const existing = result.get(row.classId);
      if (existing) {
        existing.push(detail);
      } else {
        result.set(row.classId, [detail]);
      }
    }

    return result;
  }
}
