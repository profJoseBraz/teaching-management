import type { Course } from '../../domain/course';
import type { CourseRepository } from '../ports/course-repository';

export class ListCoursesUseCase {
  constructor(private readonly courses: CourseRepository) {}

  async execute(teacherId: string): Promise<Course[]> {
    return this.courses.list(teacherId);
  }
}
