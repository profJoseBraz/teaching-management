import type { ClassDisciplineGateway } from '../../../../shared/application/ports/class-discipline-gateway';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import type { EnrollmentGateway } from '../../../../shared/application/ports/enrollment-gateway';
import type { LessonGateway } from '../../../../shared/application/ports/lesson-gateway';
import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Activity } from '../../domain/activity';
import type { ActivityRepository, CreateActivityInput } from '../ports/activity-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

/**
 * Entrada do controller: `originLessonId` e `disciplineId` são opcionais,
 * com regra cruzada — sem aula de origem, `disciplineId` é obrigatório;
 * com aula, a disciplina pode ser herdada da aula.
 */
export type CreateActivityUseCaseInput = Omit<CreateActivityInput, 'disciplineId' | 'originLessonId'> & {
  originLessonId?: string | null;
  disciplineId?: string;
};

/**
 * Decisão de design: independentemente do `mode` (INDIVIDUAL ou GROUP), a criação
 * de uma atividade sempre gera submissions PENDING para todos os alunos com
 * matrícula ativa na turma. Para atividades em GROUP, o `groupId` é atribuído
 * posteriormente via CreateActivityGroups, sem bloquear o fluxo de criação.
 *
 * Aula de origem é opcional. Quando informada, a disciplina pode ser herdada dela
 * (ou validada como idêntica). Quando ausente, `disciplineId` deve ser informado
 * e estar vinculado à turma.
 */
export class CreateActivityUseCase {
  constructor(
    private readonly activities: ActivityRepository,
    private readonly submissions: SubmissionRepository,
    private readonly classOwnership: ClassOwnershipChecker,
    private readonly lessons: LessonGateway,
    private readonly enrollments: EnrollmentGateway,
    private readonly classDisciplines: ClassDisciplineGateway,
  ) {}

  async execute(input: CreateActivityUseCaseInput): Promise<Activity> {
    const classOwned = await this.classOwnership.isOwnedByTeacher(input.classId, input.teacherId);
    if (!classOwned) {
      throw new ValidationError('Class not found for this teacher');
    }

    const originLessonId = input.originLessonId ?? null;
    let disciplineId: string;

    if (originLessonId) {
      const originLesson = await this.lessons.findById(originLessonId, input.teacherId);
      if (!originLesson) {
        throw new NotFoundError('Origin lesson not found');
      }

      if (originLesson.classId !== input.classId) {
        throw new ValidationError('Origin lesson does not belong to the informed class');
      }

      disciplineId = input.disciplineId ?? originLesson.disciplineId;
      if (input.disciplineId && input.disciplineId !== originLesson.disciplineId) {
        throw new ValidationError('disciplineId must match the origin lesson discipline');
      }
    } else {
      if (!input.disciplineId) {
        throw new ValidationError('disciplineId is required when originLessonId is omitted');
      }
      disciplineId = input.disciplineId;
    }

    const linked = await this.classDisciplines.isLinked(input.teacherId, input.classId, disciplineId);
    if (!linked) {
      throw new ValidationError('Discipline is not linked to this class');
    }

    if (input.maxScore <= 0) {
      throw new ValidationError('maxScore must be greater than zero');
    }

    const activity = await this.activities.create({
      ...input,
      originLessonId,
      disciplineId,
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
