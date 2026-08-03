import { NotFoundError } from '../../../../shared/domain/errors';
import type { CourseDisciplineDetail } from '../../domain/course-discipline';
import type { CourseDisciplineRepository } from '../ports/course-discipline-repository';
import type { CourseRepository } from '../ports/course-repository';

export class ListCourseDisciplinesUseCase {
  constructor(
    private readonly courseDisciplines: CourseDisciplineRepository,
    private readonly courses: CourseRepository,
  ) {}

  async execute(teacherId: string, courseId: string): Promise<CourseDisciplineDetail[]> {
    const course = await this.courses.findById(teacherId, courseId);
    if (!course || course.deletedAt) {
      throw new NotFoundError('Course not found');
    }

    return this.courseDisciplines.listByCourse(teacherId, courseId);
  }
}
