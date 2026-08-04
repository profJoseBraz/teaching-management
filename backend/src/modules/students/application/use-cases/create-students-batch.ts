import { ConflictError, ValidationError } from '../../../../shared/domain/errors';
import type { Student } from '../../domain/student';
import type { CreateStudentInput, StudentRepository } from '../ports/student-repository';
import { DUPLICATE_REGISTRY_MESSAGE, normalizeRegistryCode } from './create-student';

export type CreateStudentsBatchItem = {
  name: string;
  registryCode?: string | null;
  email?: string | null;
  phone?: string | null;
  notes?: string | null;
};

export type CreateStudentsBatchInput = {
  teacherId: string;
  students: CreateStudentsBatchItem[];
};

/**
 * Cria vários alunos a partir de payloads já resolvidos (pós-confirmação na UI).
 */
export class CreateStudentsBatchUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(input: CreateStudentsBatchInput): Promise<Student[]> {
    if (input.students.length === 0) {
      throw new ValidationError('Informe ao menos um aluno para cadastrar');
    }

    const existingCodes = new Set(
      (await this.students.listActiveRegistryCodes(input.teacherId)).map((code) => code.toLowerCase()),
    );
    const batchCodes = new Set<string>();
    const toCreate: CreateStudentInput[] = [];

    for (const item of input.students) {
      const name = item.name.trim();
      if (name.length < 2) {
        throw new ValidationError(`Nome inválido: ${item.name}`);
      }

      const registryCode = normalizeRegistryCode(item.registryCode);
      if (registryCode) {
        const key = registryCode.toLowerCase();
        if (existingCodes.has(key) || batchCodes.has(key)) {
          throw new ConflictError(DUPLICATE_REGISTRY_MESSAGE);
        }
        batchCodes.add(key);
      }

      toCreate.push({
        teacherId: input.teacherId,
        name,
        registryCode,
        email: item.email?.trim() || null,
        phone: item.phone?.trim() || null,
        notes: item.notes?.trim() || null,
      });
    }

    return this.students.createMany(toCreate);
  }
}
