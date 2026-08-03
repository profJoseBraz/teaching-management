import { ConflictError, NotFoundError } from '../../../../shared/domain/errors';
import type { CourseDiscipline } from '../../domain/course-discipline';
import type { CourseDisciplineRepository } from '../ports/course-discipline-repository';
import type { CourseRepository } from '../ports/course-repository';
import type { DisciplineRepository } from '../ports/discipline-repository';

export type LinkDisciplineToCourseInput = {
  teacherId: string;
  courseId: string;
  disciplineId: string;
};

export class LinkDisciplineToCourseUseCase {
  constructor(
    private readonly courseDisciplines: CourseDisciplineRepository,
    private readonly courses: CourseRepository,
    private readonly disciplines: DisciplineRepository,
  ) {}

  async execute(input: LinkDisciplineToCourseInput): Promise<CourseDiscipline> {
    const course = await this.courses.findById(input.teacherId, input.courseId);
    if (!course || course.deletedAt) {
      throw new NotFoundError('Course not found');
    }

    const discipline = await this.disciplines.findById(input.teacherId, input.disciplineId);
    if (!discipline || discipline.deletedAt) {
      throw new NotFoundError('Discipline not found');
    }

    const existingLink = await this.courseDisciplines.findLink(
      input.teacherId,
      input.courseId,
      input.disciplineId,
    );

    if (existingLink) {
      if (!existingLink.deletedAt) {
        throw new ConflictError('Discipline already linked to this course');
      }
      return this.courseDisciplines.reactivate(input.teacherId, existingLink.id);
    }

    return this.courseDisciplines.create(input);
  }
}
