import type { Student } from '../../domain/student';
import { parseStudentPasteText } from '../parse-student-paste';
import type { StudentRepository } from '../ports/student-repository';
import { normalizeRegistryCode } from './create-student';

export type PreviewStudentPasteInput = {
  teacherId: string;
  text: string;
};

export type StudentPasteCandidate = {
  /** Chave estável para seleção no cliente (`existing:{id}` ou `new:{lineNumber}`). */
  key: string;
  lineNumber: number;
  line: string;
  name: string;
  registryCode: string | null;
  email: string | null;
  phone: string | null;
  notes: string | null;
  status: 'NEW' | 'EXISTING';
  student: Student | null;
};

export type PreviewStudentPasteOutput = {
  candidates: StudentPasteCandidate[];
  skipped: Array<{ lineNumber: number; line: string; reason: string }>;
  totalParsed: number;
  totalExisting: number;
  totalNew: number;
};

/**
 * Resolve texto colado sem gravar: identifica alunos novos vs. já cadastrados
 * pela matrícula (para confirmação antes de matricular na turma).
 */
export class PreviewStudentPasteUseCase {
  constructor(private readonly students: StudentRepository) {}

  async execute(input: PreviewStudentPasteInput): Promise<PreviewStudentPasteOutput> {
    const parsed = parseStudentPasteText(input.text);
    const active = await this.students.list(input.teacherId);
    const byRegistry = new Map<string, Student>();
    for (const student of active) {
      if (student.registryCode) {
        byRegistry.set(student.registryCode.toLowerCase(), student);
      }
    }

    const candidates: StudentPasteCandidate[] = [];
    const seenExistingIds = new Set<string>();

    for (const row of parsed.students) {
      const registryCode = normalizeRegistryCode(row.registryCode);
      const existing = registryCode ? byRegistry.get(registryCode.toLowerCase()) : undefined;

      if (existing) {
        if (seenExistingIds.has(existing.id)) {
          continue;
        }
        seenExistingIds.add(existing.id);
        candidates.push({
          key: `existing:${existing.id}`,
          lineNumber: row.lineNumber,
          line: row.line,
          name: existing.name,
          registryCode: existing.registryCode,
          email: existing.email,
          phone: existing.phone,
          notes: existing.notes,
          status: 'EXISTING',
          student: existing,
        });
        continue;
      }

      candidates.push({
        key: `new:${row.lineNumber}`,
        lineNumber: row.lineNumber,
        line: row.line,
        name: row.name,
        registryCode,
        email: row.email ?? null,
        phone: row.phone ?? null,
        notes: row.notes ?? null,
        status: 'NEW',
        student: null,
      });
    }

    return {
      candidates,
      skipped: parsed.skipped,
      totalParsed: parsed.students.length,
      totalExisting: candidates.filter((c) => c.status === 'EXISTING').length,
      totalNew: candidates.filter((c) => c.status === 'NEW').length,
    };
  }
}
