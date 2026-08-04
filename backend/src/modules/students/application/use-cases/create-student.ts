import { ConflictError } from '../../../../shared/domain/errors';
import type { Student } from '../../domain/student';
import type { CreateStudentInput, StudentRepository } from '../ports/student-repository';

const DUPLICATE_REGISTRY_MESSAGE = 'Aluno já cadastrado com esta matrícula.';

export class CreateStudentUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(input: CreateStudentInput): Promise<Student> {
    const registryCode = normalizeRegistryCode(input.registryCode);
    if (registryCode) {
      const existing = await this.students.findByRegistryCode(input.teacherId, registryCode);
      if (existing) {
        throw new ConflictError(DUPLICATE_REGISTRY_MESSAGE);
      }
    }

    return this.students.create({
      ...input,
      registryCode,
    });
  }
}

export function normalizeRegistryCode(value: string | null | undefined): string | null {
  if (value == null) return null;
  const normalized = value.trim();
  return normalized.length === 0 ? null : normalized;
}

export { DUPLICATE_REGISTRY_MESSAGE };
