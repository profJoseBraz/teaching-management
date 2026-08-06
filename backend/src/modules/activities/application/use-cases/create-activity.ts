import type { AssessmentPeriodGateway } from '../../../../shared/application/ports/assessment-period-gateway';
import type { ClassDisciplineGateway } from '../../../../shared/application/ports/class-discipline-gateway';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import type { EnrollmentGateway } from '../../../../shared/application/ports/enrollment-gateway';
import type { LessonGateway } from '../../../../shared/application/ports/lesson-gateway';
import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Activity } from '../../domain/activity';
import type { ActivityRepository, CreateActivityInput } from '../ports/activity-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

/**
 * Entrada do controller: `originLessonId` e disciplinas são opcionais no schema,
 * com regra cruzada — sem aula de origem, ao menos uma disciplina é obrigatória;
 * com aula, a disciplina da aula entra automaticamente (e podem ser adicionadas outras).
 */
export type CreateActivityUseCaseInput = Omit<CreateActivityInput, 'disciplineIds' | 'originLessonId'> & {
  originLessonId?: string | null;
  disciplineIds?: string[];
};

/**
 * Decisão de design: independentemente do `mode` (INDIVIDUAL ou GROUP), a criação
 * de uma atividade sempre gera submissions PENDING para todos os alunos com
 * matrícula ativa na turma. Para atividades em GROUP, o `groupId` é atribuído
 * posteriormente via CreateActivityGroups, sem bloquear o fluxo de criação.
 *
 * Aula de origem é opcional. Disciplinas são N:N (`ActivityDiscipline`): a mesma
 * atividade pode servir a várias disciplinas da turma (ex.: LP I e LP II).
 */
export class CreateActivityUseCase {
  constructor(
    private readonly activities: ActivityRepository,
    private readonly submissions: SubmissionRepository,
    private readonly classOwnership: ClassOwnershipChecker,
    private readonly lessons: LessonGateway,
    private readonly enrollments: EnrollmentGateway,
    private readonly classDisciplines: ClassDisciplineGateway,
    private readonly assessmentPeriods: AssessmentPeriodGateway,
  ) {}

  async execute(input: CreateActivityUseCaseInput): Promise<Activity> {
    const classOwned = await this.classOwnership.isOwnedByTeacher(input.classId, input.teacherId);
    if (!classOwned) {
      throw new ValidationError('Class not found for this teacher');
    }

    await this.assessmentPeriods.assertUsableForClass({
      teacherId: input.teacherId,
      classId: input.classId,
      assessmentPeriodId: input.assessmentPeriodId,
    });

    const originLessonId = input.originLessonId ?? null;
    let disciplineIds = [...new Set(input.disciplineIds ?? [])];

    if (originLessonId) {
      const originLesson = await this.lessons.findById(originLessonId, input.teacherId);
      if (!originLesson) {
        throw new NotFoundError('Origin lesson not found');
      }

      if (originLesson.classId !== input.classId) {
        throw new ValidationError('Origin lesson does not belong to the informed class');
      }

      if (!disciplineIds.includes(originLesson.disciplineId)) {
        disciplineIds = [originLesson.disciplineId, ...disciplineIds];
      }
    } else if (disciplineIds.length === 0) {
      throw new ValidationError('At least one disciplineId is required when originLessonId is omitted');
    }

    const allLinked = await this.classDisciplines.areAllLinked(
      input.teacherId,
      input.classId,
      disciplineIds,
    );
    if (!allLinked) {
      throw new ValidationError('One or more disciplines are not linked to this class');
    }

    if (input.maxScore <= 0) {
      throw new ValidationError('maxScore must be greater than zero');
    }

    const activity = await this.activities.create({
      ...input,
      originLessonId,
      disciplineIds,
    });

    const activeStudents = await this.enrollments.listActiveStudents(input.classId);
    if (activeStudents.length > 0) {
      await this.submissions.createManyPending(
        activity.id,
        input.teacherId,
        activeStudents.map((student) => student.studentId),
      );
    }

    return activity;
  }
}
