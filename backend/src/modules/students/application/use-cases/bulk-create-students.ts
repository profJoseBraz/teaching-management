import type { Student } from '../../domain/student';
import { parseStudentPasteText } from '../parse-student-paste';
import type { StudentRepository } from '../ports/student-repository';

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

    const created = await this.students.createMany(
      parsed.students.map((row) => ({
        teacherId: input.teacherId,
        name: row.name,
        registryCode: row.registryCode ?? null,
        email: row.email ?? null,
        phone: row.phone ?? null,
        notes: row.notes ?? null,
      })),
    );

    return {
      created,
      skipped: parsed.skipped,
      totalParsed: parsed.students.length,
      totalCreated: created.length,
    };
  }
}
