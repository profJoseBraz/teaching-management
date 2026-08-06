import { ValidationError } from '../../../../shared/domain/errors';
import type { Lesson } from '../../domain/lesson';
import { CreateLessonUseCase } from './create-lesson';

export type BulkCreateLessonsInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
  assessmentPeriodId: string;
  dates: Date[];
  startTime: string;
  endTime: string;
  observations?: string | null;
};

export type BulkCreateLessonsOutput = {
  created: Lesson[];
  totalCreated: number;
};

const MAX_DATES = 200;

function toDateKey(date: Date): string {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Cria várias aulas na mesma turma com disciplina e horário compartilhados.
 * Datas duplicadas no payload são deduplicadas.
 */
export class BulkCreateLessonsUseCase {
  constructor(private readonly createLesson: CreateLessonUseCase) {}

  async execute(input: BulkCreateLessonsInput): Promise<BulkCreateLessonsOutput> {
    const uniqueByDay = new Map<string, Date>();
    for (const date of input.dates) {
      if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
        throw new ValidationError('Invalid date in dates list');
      }
      uniqueByDay.set(toDateKey(date), date);
    }

    const dates = [...uniqueByDay.values()].sort((a, b) => a.getTime() - b.getTime());
    if (dates.length === 0) {
      throw new ValidationError('Informe ao menos uma data para cadastrar aulas');
    }
    if (dates.length > MAX_DATES) {
      throw new ValidationError(`Máximo de ${MAX_DATES} aulas por lote`);
    }

    const created: Lesson[] = [];
    for (const date of dates) {
      const lesson = await this.createLesson.execute({
        teacherId: input.teacherId,
        classId: input.classId,
        disciplineId: input.disciplineId,
        assessmentPeriodId: input.assessmentPeriodId,
        date,
        startTime: input.startTime,
        endTime: input.endTime,
        observations: input.observations,
      });
      created.push(lesson);
    }

    return { created, totalCreated: created.length };
  }
}
