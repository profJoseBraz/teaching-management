import { describe, expect, it } from 'vitest';
import { ValidationError } from '../../src/shared/domain/errors';
import { parseStudentPasteText } from '../../src/modules/students/application/parse-student-paste';

describe('parseStudentPasteText', () => {
  it('parses a simple list of names', () => {
    const result = parseStudentPasteText('Ana Souza\nBruno Lima\nCarla Mendes');
    expect(result.students).toHaveLength(3);
    expect(result.students.map((s) => s.name)).toEqual(['Ana Souza', 'Bruno Lima', 'Carla Mendes']);
    expect(result.skipped).toHaveLength(0);
  });

  it('parses records with header and semicolon', () => {
    const text = [
      'Matrícula;Nome;E-mail;Telefone',
      '2026001;Ana Souza;ana@escola.com;11999990000',
      '2026002;Bruno Lima;bruno@escola.com;',
    ].join('\n');

    const result = parseStudentPasteText(text);
    expect(result.students).toHaveLength(2);
    expect(result.students[0]).toMatchObject({
      name: 'Ana Souza',
      registryCode: '2026001',
      email: 'ana@escola.com',
      phone: '11999990000',
    });
    expect(result.students[1].phone).toBeUndefined();
  });

  it('parses positional CSV without header as Matricula;Nome;Email', () => {
    const result = parseStudentPasteText('2026004,Diego Alves,diego@escola.com');
    expect(result.students).toHaveLength(1);
    expect(result.students[0]).toMatchObject({
      name: 'Diego Alves',
      registryCode: '2026004',
      email: 'diego@escola.com',
    });
  });

  it('skips invalid email and duplicate lines', () => {
    const text = ['Ana Souza', 'Ana Souza', '2026,Bruno Lima,email-invalido'].join('\n');
    const result = parseStudentPasteText(text);
    expect(result.students).toHaveLength(1);
    expect(result.students[0].name).toBe('Ana Souza');
    expect(result.skipped.length).toBeGreaterThanOrEqual(2);
  });

  it('throws when text is empty', () => {
    expect(() => parseStudentPasteText('   \n  ')).toThrow(ValidationError);
  });
});
