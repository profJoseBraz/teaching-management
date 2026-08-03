import { ConflictError } from '../../../../shared/domain/errors';
import type { Course } from '../../domain/course';
import type { CourseRepository, CreateCourseInput } from '../ports/course-repository';

export class CreateCourseUseCase {
  constructor(private readonly courses: CourseRepository) {}

  async execute(input: CreateCourseInput): Promise<Course> {
    const existing = await this.courses.findByName(input.teacherId, input.name);
    if (existing && !existing.deletedAt) {
      throw new ConflictError('Course already exists for this teacher');
    }

    return this.courses.create(input);
  }
}
