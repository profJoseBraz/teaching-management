import { ConflictError, NotFoundError, ValidationError } from '../../../../shared/domain/errors';
import type { AcademicYearRepository } from '../../../academic/application/ports/academic-year-repository';
import type { CourseRepository } from '../../../academic/application/ports/course-repository';
import type { DisciplineRepository } from '../../../academic/application/ports/discipline-repository';
import type { ClassShift, ClassWithDisciplines } from '../../domain/class';
import type { ClassDisciplineRepository } from '../ports/class-discipline-repository';
import type { ClassRepository } from '../ports/class-repository';

export type CreateClassUseCaseInput = {
  teacherId: string;
  academicYearId: string;
  courseId: string;
  name: string;
  shift?: ClassShift | null;
  /** Ao menos uma disciplina é obrigatória; `disciplineId` singular (legado) é normalizado no schema HTTP. */
  disciplineIds: string[];
};

/**
 * Cria uma turma validando que ano letivo, curso e disciplinas pertencem ao
 * professor autenticado — evita vincular turma a estrutura acadêmica de outro professor.
 * Uma turma pode ministrar N disciplinas simultaneamente, cada uma vinculada via `ClassDiscipline`.
 */
export class CreateClassUseCase {
  constructor(
    private readonly classes: ClassRepository,
    private readonly academicYears: AcademicYearRepository,
    private readonly courses: CourseRepository,
    private readonly disciplines: DisciplineRepository,
    private readonly classDisciplines: ClassDisciplineRepository,
  ) {}

  async execute(input: CreateClassUseCaseInput): Promise<ClassWithDisciplines> {
    const academicYear = await this.academicYears.findById(input.teacherId, input.academicYearId);
    if (!academicYear || academicYear.deletedAt) {
      throw new NotFoundError('Academic year not found');
    }

    const course = await this.courses.findById(input.teacherId, input.courseId);
    if (!course || course.deletedAt) {
      throw new NotFoundError('Course not found');
    }

    const disciplineIds = [...new Set(input.disciplineIds)];
    if (disciplineIds.length === 0) {
      throw new ValidationError('At least one disciplineId is required');
    }

    const disciplineSummaries: { id: string; name: string }[] = [];
    for (const disciplineId of disciplineIds) {
      const discipline = await this.disciplines.findById(input.teacherId, disciplineId);
      if (!discipline || discipline.deletedAt) {
        throw new NotFoundError('Discipline not found');
      }
      disciplineSummaries.push({ id: discipline.id, name: discipline.name });
    }

    const existing = await this.classes.findByComposition(
      input.teacherId,
      input.academicYearId,
      input.courseId,
      input.name,
    );
    if (existing && !existing.deletedAt) {
      throw new ConflictError('Class already exists for this academic year and course');
    }

    const created = await this.classes.create({
      teacherId: input.teacherId,
      academicYearId: input.academicYearId,
      courseId: input.courseId,
      name: input.name,
      shift: input.shift,
    });

    for (const disciplineId of disciplineIds) {
      await this.classDisciplines.create({
        teacherId: input.teacherId,
        classId: created.id,
        disciplineId,
      });
    }

    return { ...created, disciplineIds, disciplines: disciplineSummaries };
  }
}
