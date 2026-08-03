import type { Prisma } from '@prisma/client';
import { prisma } from '../../../shared/infra/prisma/prisma-client';
import type { ReportFilters, ReportRow } from '../domain/report';
import type { ReportsRepository } from '../application/ports/reports-repository';

const DEFAULT_EXCESS_ABSENCES_THRESHOLD = 5;

function startOfToday(): Date {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

function dateRange(filters: ReportFilters): Prisma.DateTimeFilter | undefined {
  if (!filters.from && !filters.to) {
    return undefined;
  }
  return {
    ...(filters.from ? { gte: filters.from } : {}),
    ...(filters.to ? { lte: filters.to } : {}),
  };
}

function classRelationFilter(filters: ReportFilters): Prisma.ClassWhereInput | undefined {
  if (!filters.academicYearId && !filters.courseId && !filters.disciplineId) {
    return undefined;
  }
  return {
    ...(filters.academicYearId ? { academicYearId: filters.academicYearId } : {}),
    ...(filters.courseId ? { courseId: filters.courseId } : {}),
    ...(filters.disciplineId
      ? { classDisciplines: { some: { disciplineId: filters.disciplineId, deletedAt: null } } }
      : {}),
  };
}

function lessonScope(teacherId: string, filters: ReportFilters): Prisma.LessonWhereInput {
  const classRelation = classRelationFilter(filters);
  return {
    teacherId,
    deletedAt: null,
    ...(filters.classId ? { classId: filters.classId } : {}),
    ...(classRelation ? { class: classRelation } : {}),
  };
}

function activityScope(teacherId: string, filters: ReportFilters): Prisma.ActivityWhereInput {
  const classRelation = classRelationFilter(filters);
  return {
    teacherId,
    deletedAt: null,
    ...(filters.classId ? { classId: filters.classId } : {}),
    ...(classRelation ? { class: classRelation } : {}),
    ...(filters.assessmentPeriodId ? { assessmentPeriodId: filters.assessmentPeriodId } : {}),
  };
}

function contentScope(teacherId: string, filters: ReportFilters): Prisma.ContentWhereInput {
  const classRelation = classRelationFilter(filters);
  return {
    teacherId,
    deletedAt: null,
    ...(filters.classId ? { classId: filters.classId } : {}),
    ...(classRelation ? { class: classRelation } : {}),
  };
}

export class PrismaReportsRepository implements ReportsRepository {
  /** P0 — alunos com faltas >= threshold (default 5), agrupado por aluno + turma. */
  async getExcessAbsences(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const threshold = filters.threshold ?? DEFAULT_EXCESS_ABSENCES_THRESHOLD;
    const range = dateRange(filters);

    const attendances = await prisma.attendance.findMany({
      where: {
        teacherId,
        status: 'ABSENT',
        lesson: {
          ...lessonScope(teacherId, filters),
          ...(range ? { date: range } : {}),
        },
      },
      select: {
        studentId: true,
        student: { select: { name: true } },
        lesson: { select: { classId: true, class: { select: { name: true } } } },
      },
    });

    const byStudentClass = new Map<
      string,
      { studentId: string; studentName: string; classId: string; className: string; absenceCount: number }
    >();
    for (const row of attendances) {
      const key = `${row.studentId}:${row.lesson.classId}`;
      const entry = byStudentClass.get(key);
      if (entry) {
        entry.absenceCount += 1;
      } else {
        byStudentClass.set(key, {
          studentId: row.studentId,
          studentName: row.student.name,
          classId: row.lesson.classId,
          className: row.lesson.class.name,
          absenceCount: 1,
        });
      }
    }

    return Array.from(byStudentClass.values())
      .filter((entry) => entry.absenceCount >= threshold)
      .sort((a, b) => b.absenceCount - a.absenceCount);
  }

  /** P0 — entregas PENDING (aluno ainda não entregou). */
  async getPendingActivities(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const submissions = await prisma.submission.findMany({
      where: {
        teacherId,
        deletedAt: null,
        status: 'PENDING',
        activity: {
          ...activityScope(teacherId, filters),
          ...(range ? { dueDate: range } : {}),
        },
      },
      select: {
        id: true,
        studentId: true,
        student: { select: { name: true } },
        activity: {
          select: { id: true, title: true, dueDate: true, classId: true, class: { select: { name: true } } },
        },
      },
    });

    return submissions
      .map((submission) => ({
        submissionId: submission.id,
        studentId: submission.studentId,
        studentName: submission.student.name,
        activityId: submission.activity.id,
        activityTitle: submission.activity.title,
        classId: submission.activity.classId,
        className: submission.activity.class.name,
        dueDate: submission.activity.dueDate,
      }))
      .sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());
  }

  /** P0 — atividades vencidas (dueDate < hoje) com ao menos uma entrega não GRADED. */
  async getUngradedActivities(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters) ?? {};
    const activities = await prisma.activity.findMany({
      where: {
        ...activityScope(teacherId, filters),
        dueDate: { ...range, lt: startOfToday() },
        submissions: { some: { status: { not: 'GRADED' } } },
      },
      select: {
        id: true,
        title: true,
        dueDate: true,
        classId: true,
        class: { select: { name: true } },
        submissions: { select: { status: true } },
      },
      orderBy: { dueDate: 'asc' },
    });

    return activities.map((activity) => {
      const total = activity.submissions.length;
      const graded = activity.submissions.filter((submission) => submission.status === 'GRADED').length;
      return {
        activityId: activity.id,
        title: activity.title,
        classId: activity.classId,
        className: activity.class.name,
        dueDate: activity.dueDate,
        totalSubmissions: total,
        gradedSubmissions: graded,
        pendingGrading: total - graded,
      };
    });
  }

  /** P0 — conteúdos com status IN_PROGRESS. */
  async getContentsInProgress(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const contents = await prisma.content.findMany({
      where: {
        ...contentScope(teacherId, filters),
        status: 'IN_PROGRESS',
        ...(range ? { startedAt: range } : {}),
      },
      select: { id: true, title: true, classId: true, class: { select: { name: true } }, startedAt: true },
      orderBy: { startedAt: 'asc' },
    });

    return contents.map((content) => ({
      contentId: content.id,
      title: content.title,
      classId: content.classId,
      className: content.class.name,
      startedAt: content.startedAt,
    }));
  }

  /** P0 — aulas já ocorridas (data <= hoje) sem chamada concluída. */
  async getLessonsWithoutAttendance(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters) ?? {};
    const lessons = await prisma.lesson.findMany({
      where: {
        ...lessonScope(teacherId, filters),
        attendanceCompleted: false,
        date: { ...range, lte: startOfToday() },
      },
      select: {
        id: true,
        classId: true,
        class: { select: { name: true } },
        date: true,
        startTime: true,
        endTime: true,
      },
      orderBy: { date: 'asc' },
    });

    return lessons.map((lesson) => ({
      lessonId: lesson.id,
      classId: lesson.classId,
      className: lesson.class.name,
      date: lesson.date,
      startTime: lesson.startTime,
      endTime: lesson.endTime,
    }));
  }

  /**
   * P0 — cruzamento (docs/ARCHITECTURE.md §7.24): alunos com entrega PENDING cuja
   * frequência na aula de origem da atividade foi ABSENT.
   */
  async getAbsenceVsNonSubmission(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const submissions = await prisma.submission.findMany({
      where: {
        teacherId,
        deletedAt: null,
        status: 'PENDING',
        activity: {
          ...activityScope(teacherId, filters),
          ...(range ? { dueDate: range } : {}),
        },
      },
      select: {
        id: true,
        studentId: true,
        student: { select: { name: true } },
        activity: {
          select: {
            id: true,
            title: true,
            classId: true,
            class: { select: { name: true } },
            originLessonId: true,
            originLesson: { select: { date: true } },
          },
        },
      },
    });

    if (submissions.length === 0) {
      return [];
    }

    const lessonIds = [...new Set(submissions.map((submission) => submission.activity.originLessonId))];
    const absences = await prisma.attendance.findMany({
      where: { teacherId, status: 'ABSENT', lessonId: { in: lessonIds } },
      select: { lessonId: true, studentId: true },
    });
    const absentKeys = new Set(absences.map((absence) => `${absence.lessonId}:${absence.studentId}`));

    return submissions
      .filter((submission) => absentKeys.has(`${submission.activity.originLessonId}:${submission.studentId}`))
      .map((submission) => ({
        submissionId: submission.id,
        studentId: submission.studentId,
        studentName: submission.student.name,
        activityId: submission.activity.id,
        activityTitle: submission.activity.title,
        classId: submission.activity.classId,
        className: submission.activity.class.name,
        originLessonDate: submission.activity.originLesson.date,
      }));
  }

  /**
   * P1 — percentual de presença por aluno, quebrado por turma. Simplificação de MVP:
   * calculado sobre os registros de `Attendance` existentes (não sobre todas as aulas da
   * turma), evitando o custo de cruzar com matrículas ativas por aula.
   */
  async getAttendancePercentage(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const attendances = await prisma.attendance.findMany({
      where: {
        teacherId,
        lesson: { ...lessonScope(teacherId, filters), ...(range ? { date: range } : {}) },
      },
      select: {
        studentId: true,
        status: true,
        student: { select: { name: true } },
        lesson: { select: { classId: true, class: { select: { name: true } } } },
      },
    });

    type Row = {
      studentId: string;
      studentName: string;
      classId: string;
      className: string;
      totalLessons: number;
      presentCount: number;
      absentCount: number;
      lateCount: number;
    };
    const byKey = new Map<string, Row>();
    for (const attendance of attendances) {
      const key = `${attendance.studentId}:${attendance.lesson.classId}`;
      const entry = byKey.get(key) ?? {
        studentId: attendance.studentId,
        studentName: attendance.student.name,
        classId: attendance.lesson.classId,
        className: attendance.lesson.class.name,
        totalLessons: 0,
        presentCount: 0,
        absentCount: 0,
        lateCount: 0,
      };
      entry.totalLessons += 1;
      if (attendance.status === 'PRESENT') entry.presentCount += 1;
      else if (attendance.status === 'ABSENT') entry.absentCount += 1;
      else entry.lateCount += 1;
      byKey.set(key, entry);
    }

    return Array.from(byKey.values())
      .map((entry) => ({
        ...entry,
        attendancePercentage:
          entry.totalLessons > 0
            ? Number((((entry.presentCount + entry.lateCount) / entry.totalLessons) * 100).toFixed(2))
            : 0,
      }))
      .sort((a, b) => a.studentName.localeCompare(b.studentName));
  }

  /** P1 — média das entregas corrigidas (GRADED), agrupada por turma. */
  async getClassAverage(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const submissions = await prisma.submission.findMany({
      where: {
        teacherId,
        deletedAt: null,
        status: 'GRADED',
        score: { not: null },
        activity: {
          ...activityScope(teacherId, filters),
          ...(range ? { dueDate: range } : {}),
        },
      },
      select: { score: true, activity: { select: { classId: true, class: { select: { name: true } } } } },
    });

    type Row = { classId: string; className: string; totalGradedSubmissions: number; sumScore: number };
    const byClass = new Map<string, Row>();
    for (const submission of submissions) {
      const key = submission.activity.classId;
      const entry = byClass.get(key) ?? {
        classId: key,
        className: submission.activity.class.name,
        totalGradedSubmissions: 0,
        sumScore: 0,
      };
      entry.totalGradedSubmissions += 1;
      entry.sumScore += Number(submission.score);
      byClass.set(key, entry);
    }

    return Array.from(byClass.values()).map((entry) => ({
      classId: entry.classId,
      className: entry.className,
      totalGradedSubmissions: entry.totalGradedSubmissions,
      averageScore: Number((entry.sumScore / entry.totalGradedSubmissions).toFixed(2)),
    }));
  }

  /** P1 — notas de cada aluno por atividade. */
  async getGradesByStudent(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const submissions = await prisma.submission.findMany({
      where: {
        teacherId,
        deletedAt: null,
        activity: {
          ...activityScope(teacherId, filters),
          ...(range ? { dueDate: range } : {}),
        },
      },
      select: {
        studentId: true,
        status: true,
        score: true,
        student: { select: { name: true } },
        activity: {
          select: { id: true, title: true, classId: true, class: { select: { name: true } }, maxScore: true },
        },
      },
    });

    return submissions
      .map((submission) => ({
        studentId: submission.studentId,
        studentName: submission.student.name,
        activityId: submission.activity.id,
        activityTitle: submission.activity.title,
        classId: submission.activity.classId,
        className: submission.activity.class.name,
        status: submission.status,
        score: submission.score !== null ? Number(submission.score) : null,
        maxScore: Number(submission.activity.maxScore),
      }))
      .sort((a, b) => a.studentName.localeCompare(b.studentName));
  }

  /** P1 — presença agregada por aluno, somando todas as turmas do escopo filtrado. */
  async getAttendanceByStudent(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const attendances = await prisma.attendance.findMany({
      where: {
        teacherId,
        lesson: { ...lessonScope(teacherId, filters), ...(range ? { date: range } : {}) },
      },
      select: { studentId: true, status: true, student: { select: { name: true } } },
    });

    type Row = {
      studentId: string;
      studentName: string;
      totalLessons: number;
      presentCount: number;
      absentCount: number;
      lateCount: number;
    };
    const byStudent = new Map<string, Row>();
    for (const attendance of attendances) {
      const entry = byStudent.get(attendance.studentId) ?? {
        studentId: attendance.studentId,
        studentName: attendance.student.name,
        totalLessons: 0,
        presentCount: 0,
        absentCount: 0,
        lateCount: 0,
      };
      entry.totalLessons += 1;
      if (attendance.status === 'PRESENT') entry.presentCount += 1;
      else if (attendance.status === 'ABSENT') entry.absentCount += 1;
      else entry.lateCount += 1;
      byStudent.set(attendance.studentId, entry);
    }

    return Array.from(byStudent.values())
      .map((entry) => ({
        ...entry,
        attendancePercentage:
          entry.totalLessons > 0
            ? Number((((entry.presentCount + entry.lateCount) / entry.totalLessons) * 100).toFixed(2))
            : 0,
      }))
      .sort((a, b) => a.studentName.localeCompare(b.studentName));
  }

  /** P1 — contagem de entregas por status, por atividade. */
  async getSubmissionStatus(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const activities = await prisma.activity.findMany({
      where: {
        ...activityScope(teacherId, filters),
        ...(range ? { dueDate: range } : {}),
      },
      select: {
        id: true,
        title: true,
        classId: true,
        class: { select: { name: true } },
        submissions: { select: { status: true } },
      },
    });

    return activities.map((activity) => ({
      activityId: activity.id,
      activityTitle: activity.title,
      classId: activity.classId,
      className: activity.class.name,
      pending: activity.submissions.filter((submission) => submission.status === 'PENDING').length,
      submitted: activity.submissions.filter((submission) => submission.status === 'SUBMITTED').length,
      graded: activity.submissions.filter((submission) => submission.status === 'GRADED').length,
      total: activity.submissions.length,
    }));
  }

  /** P1 — total de aulas por turma, com quantas já têm chamada concluída. */
  async getLessonsTaught(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const lessons = await prisma.lesson.findMany({
      where: { ...lessonScope(teacherId, filters), ...(range ? { date: range } : {}) },
      select: { classId: true, class: { select: { name: true } }, attendanceCompleted: true },
    });

    type Row = { classId: string; className: string; totalLessons: number; lessonsWithAttendance: number };
    const byClass = new Map<string, Row>();
    for (const lesson of lessons) {
      const entry = byClass.get(lesson.classId) ?? {
        classId: lesson.classId,
        className: lesson.class.name,
        totalLessons: 0,
        lessonsWithAttendance: 0,
      };
      entry.totalLessons += 1;
      if (lesson.attendanceCompleted) entry.lessonsWithAttendance += 1;
      byClass.set(lesson.classId, entry);
    }

    return Array.from(byClass.values());
  }

  /** P1 — alunos com entregas sem nota lançada (score null), agrupado por turma. */
  async getStudentsWithoutGrade(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const submissions = await prisma.submission.findMany({
      where: {
        teacherId,
        deletedAt: null,
        score: null,
        activity: {
          ...activityScope(teacherId, filters),
          ...(range ? { dueDate: range } : {}),
        },
      },
      select: {
        studentId: true,
        student: { select: { name: true } },
        activity: { select: { classId: true, class: { select: { name: true } } } },
      },
    });

    type Row = { studentId: string; studentName: string; classId: string; className: string; ungradedCount: number };
    const byKey = new Map<string, Row>();
    for (const submission of submissions) {
      const key = `${submission.studentId}:${submission.activity.classId}`;
      const entry = byKey.get(key) ?? {
        studentId: submission.studentId,
        studentName: submission.student.name,
        classId: submission.activity.classId,
        className: submission.activity.class.name,
        ungradedCount: 0,
      };
      entry.ungradedCount += 1;
      byKey.set(key, entry);
    }

    return Array.from(byKey.values()).sort((a, b) => b.ungradedCount - a.ungradedCount);
  }

  /** P1 — média e volume de entregas por atividade. */
  async getAverageByActivity(teacherId: string, filters: ReportFilters): Promise<ReportRow[]> {
    const range = dateRange(filters);
    const activities = await prisma.activity.findMany({
      where: {
        ...activityScope(teacherId, filters),
        ...(range ? { dueDate: range } : {}),
      },
      select: {
        id: true,
        title: true,
        classId: true,
        class: { select: { name: true } },
        maxScore: true,
        submissions: { select: { status: true, score: true } },
      },
    });

    return activities.map((activity) => {
      const graded = activity.submissions.filter(
        (submission) => submission.status === 'GRADED' && submission.score !== null,
      );
      const averageScore =
        graded.length > 0
          ? Number((graded.reduce((sum, submission) => sum + Number(submission.score), 0) / graded.length).toFixed(2))
          : null;

      return {
        activityId: activity.id,
        title: activity.title,
        classId: activity.classId,
        className: activity.class.name,
        maxScore: Number(activity.maxScore),
        totalSubmissions: activity.submissions.length,
        gradedCount: graded.length,
        averageScore,
      };
    });
  }
}
