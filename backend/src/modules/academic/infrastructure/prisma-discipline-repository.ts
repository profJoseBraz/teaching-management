import type { Discipline as PrismaDiscipline } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { Discipline } from '../domain/discipline';
import type {
  DisciplineRepository,
  CreateDisciplineInput,
  UpdateDisciplineInput,
} from '../application/ports/discipline-repository';

function mapDiscipline(row: PrismaDiscipline): Discipline {
  return {
    id: row.id,
    teacherId: row.teacherId,
    name: row.name,
    description: row.description,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  };
}

export class PrismaDisciplineRepository implements DisciplineRepository {
  async create(input: CreateDisciplineInput): Promise<Discipline> {
    const row = await prisma.discipline.create({
      data: {
        teacherId: input.teacherId,
        name: input.name,
        description: input.description ?? null,
      },
    });
    return mapDiscipline(row);
  }

  async findById(teacherId: string, id: string): Promise<Discipline | null> {
    const row = await prisma.discipline.findFirst({ where: { id, teacherId } });
    return row ? mapDiscipline(row) : null;
  }

  async findByName(teacherId: string, name: string): Promise<Discipline | null> {
    const row = await prisma.discipline.findFirst({ where: { teacherId, name } });
    return row ? mapDiscipline(row) : null;
  }

  async list(teacherId: string): Promise<Discipline[]> {
    const rows = await prisma.discipline.findMany({
      where: { teacherId, deletedAt: null },
      orderBy: { name: 'asc' },
    });
    return rows.map(mapDiscipline);
  }

  async update(teacherId: string, id: string, input: UpdateDisciplineInput): Promise<Discipline> {
    await prisma.discipline.updateMany({
      where: { id, teacherId },
      data: {
        ...(input.name !== undefined ? { name: input.name } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
      },
    });
    const row = await prisma.discipline.findFirstOrThrow({ where: { id, teacherId } });
    return mapDiscipline(row);
  }

  async softDelete(teacherId: string, id: string): Promise<void> {
    await prisma.discipline.updateMany({
      where: { id, teacherId },
      data: { deletedAt: new Date() },
    });
  }
}
