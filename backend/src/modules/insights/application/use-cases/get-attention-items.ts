import type { AttentionItem, AttentionSeverity, AttentionType } from '../../domain/attention-item';
import type { InsightsRepository, InsightsScopeFilters } from '../ports/insights-repository';

export type GetAttentionItemsInput = {
  teacherId: string;
  academicYearId?: string;
  classId?: string;
};

/** Regra de negócio (docs/ARCHITECTURE.md §7.25): limiar de faltas para EXCESS_ABSENCES. */
export const EXCESS_ABSENCES_THRESHOLD = 5;

const SEVERITY_WEIGHT: Record<AttentionSeverity, number> = { high: 0, medium: 1, low: 2 };

type AttentionItemDescriptor = {
  type: AttentionType;
  severity: AttentionSeverity;
  count: number;
  title: string;
  message: string;
  actionRoute: string;
};

function toAttentionItem(
  descriptor: AttentionItemDescriptor,
  scopeFilters: { academicYearId?: string; classId?: string },
): AttentionItem {
  return {
    id: descriptor.type,
    type: descriptor.type,
    severity: descriptor.severity,
    title: descriptor.title,
    message: descriptor.message,
    count: descriptor.count,
    actionRoute: descriptor.actionRoute,
    filters: { ...scopeFilters },
  };
}

function pluralize(count: number, singular: string, plural: string): string {
  return count === 1 ? singular : plural;
}

export class GetAttentionItemsUseCase {
  constructor(private readonly insights: InsightsRepository) {}

  async execute(input: GetAttentionItemsInput): Promise<AttentionItem[]> {
    const scope: InsightsScopeFilters = {
      teacherId: input.teacherId,
      academicYearId: input.academicYearId,
      classId: input.classId,
    };
    const scopeFilters = { academicYearId: input.academicYearId, classId: input.classId };

    const [
      lessonsWithoutAttendance,
      overdueUngradedActivities,
      submissionsAwaitingGrade,
      contentsInProgress,
      studentsPendingSubmission,
      absentOnActivityLesson,
      studentsWithExcessAbsences,
      activitiesWithoutScore,
    ] = await Promise.all([
      this.insights.countLessonsWithoutAttendance(scope),
      this.insights.countOverdueUngradedActivities(scope),
      this.insights.countSubmissionsAwaitingGrade(scope),
      this.insights.countContentsInProgress(scope),
      this.insights.countStudentsPendingSubmission(scope),
      this.insights.countAbsentOnActivityLesson(scope),
      this.insights.countStudentsWithExcessAbsences(scope, EXCESS_ABSENCES_THRESHOLD),
      this.insights.countActivitiesWithoutScore(scope),
    ]);

    const descriptors: AttentionItemDescriptor[] = [
      {
        type: 'LESSONS_WITHOUT_ATTENDANCE',
        severity: 'high',
        count: lessonsWithoutAttendance,
        title: `${lessonsWithoutAttendance} ${pluralize(lessonsWithoutAttendance, 'aula sem', 'aulas sem')} frequência lançada`,
        message: 'Aulas já realizadas que ainda não tiveram a chamada registrada.',
        actionRoute: '/lessons?attendanceCompleted=false',
      },
      {
        type: 'OVERDUE_UNGRADED_ACTIVITIES',
        severity: 'high',
        count: overdueUngradedActivities,
        title: `${overdueUngradedActivities} ${pluralize(overdueUngradedActivities, 'atividade vencida', 'atividades vencidas')} sem correção completa`,
        message: 'Atividades com prazo esgotado que ainda têm entregas não corrigidas.',
        actionRoute: '/activities?filter=overdue-ungraded',
      },
      {
        type: 'ACTIVITIES_AWAITING_GRADE',
        severity: 'high',
        count: submissionsAwaitingGrade,
        title: `${submissionsAwaitingGrade} ${pluralize(submissionsAwaitingGrade, 'entrega', 'entregas')} aguardando correção`,
        message: 'Entregas já realizadas pelos alunos, aguardando nota do professor.',
        actionRoute: '/submissions?status=SUBMITTED',
      },
      {
        type: 'CONTENTS_IN_PROGRESS',
        severity: 'medium',
        count: contentsInProgress,
        title: `${contentsInProgress} ${pluralize(contentsInProgress, 'conteúdo em andamento', 'conteúdos em andamento')}`,
        message: 'Conteúdos ainda não marcados como concluídos pelo professor.',
        actionRoute: '/contents?status=IN_PROGRESS',
      },
      {
        type: 'STUDENTS_PENDING_SUBMISSION',
        severity: 'medium',
        count: studentsPendingSubmission,
        title: `${studentsPendingSubmission} ${pluralize(studentsPendingSubmission, 'entrega pendente', 'entregas pendentes')} de atividades já vencidas`,
        message: 'Alunos que ainda não entregaram atividades com prazo esgotado.',
        actionRoute: '/submissions?status=PENDING&overdue=true',
      },
      {
        type: 'ABSENT_ON_ACTIVITY_LESSON',
        severity: 'medium',
        count: absentOnActivityLesson,
        title: `${absentOnActivityLesson} ${pluralize(absentOnActivityLesson, 'pendência', 'pendências')} de aluno ausente na aula de origem`,
        message: 'Alunos que faltaram na aula de origem da atividade e ainda não entregaram.',
        actionRoute: '/reports/absence-vs-non-submission',
      },
      {
        type: 'EXCESS_ABSENCES',
        severity: 'high',
        count: studentsWithExcessAbsences,
        title: `${studentsWithExcessAbsences} ${pluralize(studentsWithExcessAbsences, 'aluno', 'alunos')} com excesso de faltas`,
        message: `Alunos com ${EXCESS_ABSENCES_THRESHOLD} ou mais faltas registradas no período.`,
        actionRoute: '/reports/excess-absences',
      },
      {
        type: 'ACTIVITIES_WITHOUT_SCORE',
        severity: 'medium',
        count: activitiesWithoutScore,
        title: `${activitiesWithoutScore} ${pluralize(activitiesWithoutScore, 'atividade', 'atividades')} sem nenhuma nota lançada`,
        message: 'Atividades dentro do prazo com entregas aguardando o lançamento de notas.',
        actionRoute: '/activities?filter=without-score',
      },
    ];

    return descriptors
      .filter((descriptor) => descriptor.count > 0)
      .map((descriptor) => toAttentionItem(descriptor, scopeFilters))
      .sort((a, b) => {
        const severityDiff = SEVERITY_WEIGHT[a.severity] - SEVERITY_WEIGHT[b.severity];
        return severityDiff !== 0 ? severityDiff : b.count - a.count;
      });
  }
}
