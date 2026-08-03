import type { ClassDisciplineGateway } from '../../../../shared/application/ports/class-discipline-gateway';
import type { ClassOwnershipChecker } from '../../../../shared/application/ports/class-ownership-checker';
import type { EnrollmentGateway } from '../../../../shared/application/ports/enrollment-gateway';
import type { LessonGateway } from '../../../../shared/application/ports/lesson-gateway';
import { NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { Activity } from '../../domain/activity';
import type { ActivityRepository, CreateActivityInput } from '../ports/activity-repository';
import type { SubmissionRepository } from '../ports/submission-repository';

/** Entrada aceita pelo controller: `disciplineId` é opcional — quando ausente, herda da `originLesson`. */
export type CreateActivityUseCaseInput = Omit<CreateActivityInput, 'disciplineId'> & {
  disciplineId?: string;
};

/**
 * Decisão de design: independentemente do `mode` (INDIVIDUAL ou GROUP), a criação
 * de uma atividade sempre gera submissions PENDING para todos os alunos com
 * matrícula ativa na turma. Para atividades em GROUP, o `groupId` é atribuído
 * posteriormente via CreateActivityGroups, sem bloquear o fluxo de criação.
 *
 * A disciplina da atividade sempre coincide com a disciplina da `originLesson`:
 * quando o body não informa `disciplineId`, ele é herdado da aula de origem;
 * quando informado, deve ser idêntico ao da aula (e vinculado ativamente à turma).
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

    const originLesson = await this.lessons.findById(input.originLessonId, input.teacherId);
    if (!originLesson) {
      throw new NotFoundError('Origin lesson not found');
    }

    if (originLesson.classId !== input.classId) {
      throw new ValidationError('Origin lesson does not belong to the informed class');
    }

    const disciplineId = input.disciplineId ?? originLesson.disciplineId;
    if (disciplineId !== originLesson.disciplineId) {
      throw new ValidationError('disciplineId must match the origin lesson discipline');
    }

    const linked = await this.classDisciplines.isLinked(input.teacherId, input.classId, disciplineId);
    if (!linked) {
      throw new ValidationError('Discipline is not linked to this class');
    }

    if (input.maxScore <= 0) {
      throw new ValidationError('maxScore must be greater than zero');
    }

    const activity = await this.activities.create({ ...input, disciplineId });

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
