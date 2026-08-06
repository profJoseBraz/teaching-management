import type { AgendaNote as PrismaAgendaNote } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { AgendaNote } from '../domain/agenda-note';
import type {
  AgendaNoteRepository,
  CreateAgendaNoteInput,
  ListAgendaNotesFilters,
  UpdateAgendaNoteInput,
} from '../application/ports/agenda-note-repository';

/** Normaliza para meia-noite UTC (coluna DATE). */
export function toDateOnly(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function mapAgendaNote(row: PrismaAgendaNote): AgendaNote {
  return {
    id: row.id,
    teacherId: row.teacherId,
    date: row.date,
    content: row.content,
    completed: row.completed,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

export class PrismaAgendaNoteRepository implements AgendaNoteRepository {
  async create(input: CreateAgendaNoteInput): Promise<AgendaNote> {
    const row = await prisma.agendaNote.create({
      data: {
        teacherId: input.teacherId,
        date: toDateOnly(input.date),
        content: input.content,
        completed: input.completed ?? false,
      },
    });
    return mapAgendaNote(row);
  }

  async findById(teacherId: string, id: string): Promise<AgendaNote | null> {
    const row = await prisma.agendaNote.findFirst({ where: { id, teacherId } });
    return row ? mapAgendaNote(row) : null;
  }

  async list(teacherId: string, filters?: ListAgendaNotesFilters): Promise<AgendaNote[]> {
    const from = filters?.from ? toDateOnly(filters.from) : undefined;
    const to = filters?.to ? toDateOnly(filters.to) : undefined;
    const search = filters?.search?.trim();

    const rows = await prisma.agendaNote.findMany({
      where: {
        teacherId,
        ...(filters?.completed !== undefined ? { completed: filters.completed } : {}),
        ...(from || to
          ? {
              date: {
                ...(from ? { gte: from } : {}),
                ...(to ? { lte: to } : {}),
              },
            }
          : {}),
        ...(search
          ? {
              content: { contains: search, mode: 'insensitive' },
            }
          : {}),
      },
      orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
    });
    return rows.map(mapAgendaNote);
  }

  async update(teacherId: string, id: string, input: UpdateAgendaNoteInput): Promise<AgendaNote> {
    await prisma.agendaNote.updateMany({
      where: { id, teacherId },
      data: {
        ...(input.date !== undefined ? { date: toDateOnly(input.date) } : {}),
        ...(input.content !== undefined ? { content: input.content } : {}),
        ...(input.completed !== undefined ? { completed: input.completed } : {}),
      },
    });
    const row = await prisma.agendaNote.findFirstOrThrow({ where: { id, teacherId } });
    return mapAgendaNote(row);
  }

  async delete(teacherId: string, id: string): Promise<void> {
    await prisma.agendaNote.deleteMany({ where: { id, teacherId } });
  }
}
