import { ConflictError, NotFoundError } from '../../../../shared/domain/errors';
import type { Student } from '../../domain/student';
import type { StudentRepository, UpdateStudentInput } from '../ports/student-repository';
import { DUPLICATE_REGISTRY_MESSAGE, normalizeRegistryCode } from './create-student';

export class UpdateStudentUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(teacherId: string, id: string, input: UpdateStudentInput): Promise<Student> {
    const existing = await this.students.findById(teacherId, id);
    if (!existing || existing.deletedAt) {
      throw new NotFoundError('Student not found');
    }

    const patch: UpdateStudentInput = { ...input };
    if (input.registryCode !== undefined) {
      const registryCode = normalizeRegistryCode(input.registryCode);
      patch.registryCode = registryCode;
      if (registryCode) {
        const duplicate = await this.students.findByRegistryCode(teacherId, registryCode, id);
        if (duplicate) {
          throw new ConflictError(DUPLICATE_REGISTRY_MESSAGE);
        }
      }
    }

    return this.students.update(teacherId, id, patch);
  }
}
