import { ConflictError, NotFoundError } from '../../../../shared/domain/errors';
import type { Course } from '../../domain/course';
import type { CourseRepository, UpdateCourseInput } from '../ports/course-repository';

export class UpdateCourseUseCase {
  constructor(private readonly courses: CourseRepository) {}

  async execute(teacherId: string, id: string, input: UpdateCourseInput): Promise<Course> {
    const existing = await this.courses.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Course not found');
    }

    if (input.name && input.name !== existing.name) {
      const withSameName = await this.courses.findByName(teacherId, input.name);
      if (withSameName && !withSameName.deletedAt && withSameName.id !== id) {
        throw new ConflictError('Course already exists for this teacher');
      }
    }

    return this.courses.update(teacherId, id, input);
  }
}
