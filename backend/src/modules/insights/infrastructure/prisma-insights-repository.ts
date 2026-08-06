import type { Prisma } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { InsightsRepository, InsightsScopeFilters } from '../application/ports/insights-repository';

function startOfToday(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

function classRelationFilter(filters: InsightsScopeFilters): Prisma.ClassWhereInput | undefined {
  return filters.academicYearId ? { academicYearId: filters.academicYearId } : undefined;
}

export class PrismaInsightsRepository implements InsightsRepository {
  /** Regra (docs/ARCHITECTURE.md §7.27): aula sem frequência = attendanceCompleted=false e data <= hoje. */
  async countLessonsWithoutAttendance(filters: InsightsScopeFilters): Promise<number> {
    const classRelation = classRelationFilter(filters);
    return prisma.lesson.count({
      where: {
        teacherId: filters.teacherId,
        deletedAt: null,
        attendanceCompleted: false,
        date: { lte: startOfToday() },
        ...(filters.classId ? { classId: filters.classId } : {}),
        ...(classRelation ? { class: classRelation } : {}),
      },
    });
  }

  /** Regra (docs/ARCHITECTURE.md §7.26): dueDate < hoje, não marcada Avaliada, com submission não GRADED. */
  async countOverdueUngradedActivities(filters: InsightsScopeFilters): Promise<number> {
    const classRelation = classRelationFilter(filters);
    return prisma.activity.count({
      where: {
        teacherId: filters.teacherId,
        deletedAt: null,
        evaluated: false,
        dueDate: { lt: startOfToday() },
        ...(filters.classId ? { classId: filters.classId } : {}),
        ...(classRelation ? { class: classRelation } : {}),
        submissions: { some: { status: { not: 'GRADED' } } },
      },
    });
  }

  /** Fila de correção: entregas já realizadas (SUBMITTED) aguardando nota, independente do prazo. */
  async countSubmissionsAwaitingGrade(filters: InsightsScopeFilters): Promise<number> {
    const classRelation = classRelationFilter(filters);
    return prisma.submission.count({
      where: {
        teacherId: filters.teacherId,
        deletedAt: null,
        status: 'SUBMITTED',
        activity: {
          ...(filters.classId ? { classId: filters.classId } : {}),
          ...(classRelation ? { class: classRelation } : {}),
        },
      },
    });
  }

  /** Regra (docs/ARCHITECTURE.md §7.28): conteúdo em andamento = status IN_PROGRESS. */
  async countContentsInProgress(filters: InsightsScopeFilters): Promise<number> {
    const classRelation = classRelationFilter(filters);
    return prisma.content.count({
      where: {
        teacherId: filters.teacherId,
        deletedAt: null,
        status: 'IN_PROGRESS',
        ...(filters.classId ? { classId: filters.classId } : {}),
        ...(classRelation ? { class: classRelation } : {}),
      },
    });
  }

  /** Entregas pendentes de atividades cujo prazo já se esgotou. */
  async countStudentsPendingSubmission(filters: InsightsScopeFilters): Promise<number> {
    const classRelation = classRelationFilter(filters);
    return prisma.submission.count({
      where: {
        teacherId: filters.teacherId,
        deletedAt: null,
        status: 'PENDING',
        activity: {
          dueDate: { lte: startOfToday() },
          ...(filters.classId ? { classId: filters.classId } : {}),
          ...(classRelation ? { class: classRelation } : {}),
        },
      },
    });
  }

  /**
   * Regra (docs/ARCHITECTURE.md §7.24): "não entregou e estava ausente na aula de origem" =
   * submission PENDING + attendance ABSENT na `originLesson`. Não há relação direta no Prisma
   * entre Submission e Attendance, então o cruzamento é feito em duas consultas e comparado
   * em memória (apenas leitura, sem regra de negócio).
   */
  async countAbsentOnActivityLesson(filters: InsightsScopeFilters): Promise<number> {
    const classRelation = classRelationFilter(filters);
    const submissions = await prisma.submission.findMany({
      where: {
        teacherId: filters.teacherId,
        deletedAt: null,
        status: 'PENDING',
        activity: {
          ...(filters.classId ? { classId: filters.classId } : {}),
          ...(classRelation ? { class: classRelation } : {}),
        },
      },
      select: { studentId: true, activity: { select: { originLessonId: true } } },
    });

    if (submissions.length === 0) {
      return 0;
    }

    const withOriginLesson = submissions.filter(
      (submission) => submission.activity.originLessonId != null,
    );
    const lessonIds = [
      ...new Set(withOriginLesson.map((submission) => submission.activity.originLessonId!)),
    ];
    if (lessonIds.length === 0) {
      return 0;
    }

    const absences = await prisma.attendance.findMany({
      where: { teacherId: filters.teacherId, status: 'ABSENT', lessonId: { in: lessonIds } },
      select: { lessonId: true, studentId: true },
    });

    const absentKeys = new Set(absences.map((absence) => `${absence.lessonId}:${absence.studentId}`));
    return withOriginLesson.filter((submission) =>
      absentKeys.has(`${submission.activity.originLessonId}:${submission.studentId}`),
    ).length;
  }

  /** Regra (docs/ARCHITECTURE.md §7.25 / RF): alunos com faltas >= limiar no escopo filtrado. */
  async countStudentsWithExcessAbsences(filters: InsightsScopeFilters, threshold: number): Promise<number> {
    const classRelation = classRelationFilter(filters);
    const lessonFilter =
      filters.classId || classRelation
        ? { ...(filters.classId ? { classId: filters.classId } : {}), ...(classRelation ? { class: classRelation } : {}) }
        : undefined;

    const grouped = await prisma.attendance.groupBy({
      by: ['studentId'],
      where: {
        teacherId: filters.teacherId,
        status: 'ABSENT',
        ...(lessonFilter ? { lesson: lessonFilter } : {}),
      },
      _count: { _all: true },
    });

    return grouped.filter((group) => group._count._all >= threshold).length;
  }

  /**
   * Decisão de design: para não confundir com ACTIVITIES_AWAITING_GRADE (fila de correção,
   * qualquer prazo), este item cobre apenas atividades ainda dentro do prazo (dueDate >= hoje)
   * que já têm pelo menos uma entrega SUBMITTED sem nota — aviso proativo antes de vencer.
   */
  async countActivitiesWithoutScore(filters: InsightsScopeFilters): Promise<number> {
    const classRelation = classRelationFilter(filters);
    return prisma.activity.count({
      where: {
        teacherId: filters.teacherId,
        deletedAt: null,
        dueDate: { gte: startOfToday() },
        ...(filters.classId ? { classId: filters.classId } : {}),
        ...(classRelation ? { class: classRelation } : {}),
        submissions: { some: { status: 'SUBMITTED', score: null } },
      },
    });
  }
}
