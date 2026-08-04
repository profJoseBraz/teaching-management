import { ValidationError } from '../../../shared/domain/errors';

export type ParsedStudentRow = {
  name: string;
  registryCode?: string;
  email?: string;
  phone?: string;
  notes?: string;
  lineNumber: number;
};

export type ParseStudentPasteResult = {
  students: ParsedStudentRow[];
  skipped: Array<{ lineNumber: number; line: string; reason: string }>;
};

type FieldKey = 'name' | 'registryCode' | 'email' | 'phone' | 'notes';

const HEADER_ALIASES: Record<FieldKey, string[]> = {
  name: ['nome', 'name', 'aluno', 'student'],
  registryCode: ['matricula', 'matricula', 'registro', 'registry', 'registrycode', 'ra', 'codigo', 'código'],
  email: ['email', 'e-mail', 'mail'],
  phone: ['telefone', 'phone', 'celular', 'fone', 'whatsapp'],
  notes: ['observacoes', 'observações', 'observacao', 'observação', 'notes', 'obs', 'anotacoes', 'anotações'],
};

function normalizeHeader(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim()
    .toLowerCase()
    .replace(/[\s_]+/g, '');
}

function resolveField(header: string): FieldKey | null {
  const normalized = normalizeHeader(header);
  for (const [field, aliases] of Object.entries(HEADER_ALIASES) as Array<[FieldKey, string[]]>) {
    if (aliases.some((alias) => normalizeHeader(alias) === normalized)) {
      return field;
    }
  }
  return null;
}

function detectDelimiter(line: string): string | null {
  if (line.includes('\t')) return '\t';
  if (line.includes(';')) return ';';
  if (line.includes(',')) return ',';
  return null;
}

/** Split CSV-like line respecting simple quoted values. */
function splitLine(line: string, delimiter: string): string[] {
  const cells: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }
    if (char === delimiter && !inQuotes) {
      cells.push(current.trim());
      current = '';
      continue;
    }
    current += char;
  }
  cells.push(current.trim());
  return cells.map((cell) => cell.replace(/^"(.*)"$/, '$1').trim());
}

function looksLikeHeader(cells: string[]): boolean {
  return cells.some((cell) => resolveField(cell) !== null);
}

function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

/**
 * Interpreta texto colado pelo professor.
 * Aceita:
 * - um nome por linha
 * - Matrícula;Nome;E-mail;Telefone;Obs (ou vírgula/tab)
 * - com ou sem linha de cabeçalho
 */
export function parseStudentPasteText(text: string): ParseStudentPasteResult {
  const raw = text.replace(/^\uFEFF/, '').trim();
  if (!raw) {
    throw new ValidationError('Cole ao menos um nome ou registro de aluno');
  }

  const lines = raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .map((line, index) => ({ line, lineNumber: index + 1 }))
    .filter((item) => item.line.length > 0);

  if (lines.length === 0) {
    throw new ValidationError('Cole ao menos um nome ou registro de aluno');
  }

  const firstDelimiter = detectDelimiter(lines[0].line);
  const firstCells = firstDelimiter ? splitLine(lines[0].line, firstDelimiter) : [lines[0].line];
  const hasHeader = firstCells.length > 1 && looksLikeHeader(firstCells);

  let columnMap: FieldKey[] | null = null;
  let dataLines = lines;

  if (hasHeader && firstDelimiter) {
    columnMap = firstCells.map((cell) => resolveField(cell) ?? 'name');
    if (!columnMap.includes('name')) {
      throw new ValidationError('A linha de cabeçalho precisa incluir a coluna Nome');
    }
    dataLines = lines.slice(1);
  }

  const students: ParsedStudentRow[] = [];
  const skipped: ParseStudentPasteResult['skipped'] = [];
  const seenNames = new Set<string>();

  for (const { line, lineNumber } of dataLines) {
    const delimiter = detectDelimiter(line);
    const cells = delimiter ? splitLine(line, delimiter) : [line];

    let name = '';
    let registryCode: string | undefined;
    let email: string | undefined;
    let phone: string | undefined;
    let notes: string | undefined;

    if (columnMap) {
      columnMap.forEach((field, index) => {
        const value = cells[index]?.trim();
        if (!value) return;
        if (field === 'name') name = value;
        if (field === 'registryCode') registryCode = value;
        if (field === 'email') email = value;
        if (field === 'phone') phone = value;
        if (field === 'notes') notes = value;
      });
    } else if (cells.length === 1) {
      // Lista simples: apenas o nome
      name = cells[0];
    } else {
      // Posicional: Matrícula, Nome, E-mail, Telefone, Observações
      registryCode = cells[0] || undefined;
      name = cells[1] ?? '';
      email = cells[2] || undefined;
      phone = cells[3] || undefined;
      notes = cells[4] || undefined;
    }

    name = name.trim();
    if (name.length < 2) {
      skipped.push({ lineNumber, line, reason: 'Nome inválido ou ausente' });
      continue;
    }

    if (email && !isValidEmail(email)) {
      skipped.push({ lineNumber, line, reason: `E-mail inválido: ${email}` });
      continue;
    }

    const dedupeKey = `${name.toLowerCase()}|${(registryCode ?? '').toLowerCase()}`;
    if (seenNames.has(dedupeKey)) {
      skipped.push({ lineNumber, line, reason: 'Linha duplicada no texto colado' });
      continue;
    }
    seenNames.add(dedupeKey);

    students.push({
      name,
      registryCode,
      email,
      phone,
      notes,
      lineNumber,
    });
  }

  if (students.length === 0) {
    throw new ValidationError('Nenhum aluno válido encontrado no texto colado');
  }

  return { students, skipped };
}
