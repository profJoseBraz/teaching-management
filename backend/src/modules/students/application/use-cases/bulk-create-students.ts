import type { Student } from '../../domain/student';
import { parseStudentPasteText } from '../parse-student-paste';
import type { CreateStudentInput, StudentRepository } from '../ports/student-repository';
import { DUPLICATE_REGISTRY_MESSAGE, normalizeRegistryCode } from './create-student';

export type BulkCreateStudentsInput = {
  teacherId: string;
  text: string;
};

export type BulkCreateStudentsOutput = {
  created: Student[];
  skipped: Array<{ lineNumber: number; line: string; reason: string }>;
  totalParsed: number;
  totalCreated: number;
};

export class BulkCreateStudentsUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(input: BulkCreateStudentsInput): Promise<BulkCreateStudentsOutput> {
    const parsed = parseStudentPasteText(input.text);
    const existingCodes = new Set(
      (await this.students.listActiveRegistryCodes(input.teacherId)).map((code) => code.toLowerCase()),
    );

    const toCreate: CreateStudentInput[] = [];
    const skipped = [...parsed.skipped];

    for (const row of parsed.students) {
      const registryCode = normalizeRegistryCode(row.registryCode);
      if (registryCode) {
        const key = registryCode.toLowerCase();
        if (existingCodes.has(key)) {
          skipped.push({
            lineNumber: row.lineNumber,
            line: row.line,
            reason: DUPLICATE_REGISTRY_MESSAGE,
          });
          continue;
        }
        existingCodes.add(key);
      }

      toCreate.push({
        teacherId: input.teacherId,
        name: row.name,
        registryCode,
        email: row.email ?? null,
        phone: row.phone ?? null,
        notes: row.notes ?? null,
      });
    }

    const created = await this.students.createMany(toCreate);

    return {
      created,
      skipped,
      totalParsed: parsed.students.length,
      totalCreated: created.length,
    };
  }
}
