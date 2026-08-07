import type { GradeCompositionCalculationMethod } from './grade-composition';

/**
 * Arredonda a nota convertida **sempre para cima** (teto), para inteiro.
 * Evita valores decimais na composição (ex.: 18.4 → 19).
 */
export function roundScore(value: number): number {
  // Compensa lixo de ponto flutuante perto de inteiros (ex.: 36.0000000002).
  const normalized = Math.round(value * 1e9) / 1e9;
  return Math.ceil(normalized);
}

/**
 * Normaliza a nota da atividade para escala 0–100.
 * score / activity.maxScore * 100
 */
export function normalizeActivityScore(score: number, activityMaxScore: number): number {
  if (activityMaxScore <= 0) {
    throw new Error('activityMaxScore must be greater than zero');
  }
  return (score / activityMaxScore) * 100;
}

export type ActivityScoreInput = {
  /** null = aluno sem nota nesta atividade. */
  score: number | null;
  activityMaxScore: number;
  weight: number | null;
};

/**
 * Calcula a nota convertida do grupo na escala do item do modelo (itemMaxScore).
 *
 * - Se o aluno não tem nota em **nenhuma** atividade do grupo → `null`
 *   (sem nota ≠ zero no resultado final).
 * - Se tem nota em pelo menos uma, as atividades sem nota entram como **0**
 *   na média (entrega faltante reduz a nota do item).
 * - Resultado final arredondado para cima (inteiro).
 */
export function calculateGroupConvertedScore(
  method: GradeCompositionCalculationMethod,
  entries: ActivityScoreInput[],
  itemMaxScore: number,
): number | null {
  if (entries.length === 0) {
    return null;
  }

  const hasAnyGrade = entries.some((entry) => entry.score !== null);
  if (!hasAnyGrade) {
    return null;
  }

  const normalizedEntries = entries.map((entry) => ({
    normalized:
      entry.score === null
        ? 0
        : normalizeActivityScore(entry.score, entry.activityMaxScore),
    weight: entry.weight,
  }));

  let meanOn100: number;

  if (method === 'SIMPLE_AVERAGE') {
    meanOn100 =
      normalizedEntries.reduce((sum, entry) => sum + entry.normalized, 0) /
      normalizedEntries.length;
  } else {
    const weighted = normalizedEntries.filter(
      (entry) => entry.weight !== null && entry.weight > 0,
    );
    if (weighted.length === 0) {
      return null;
    }
    const totalWeight = weighted.reduce((sum, entry) => sum + (entry.weight as number), 0);
    meanOn100 =
      weighted.reduce((sum, entry) => sum + entry.normalized * (entry.weight as number), 0) /
      totalWeight;
  }

  const converted = (meanOn100 / 100) * itemMaxScore;
  return Math.min(roundScore(converted), roundScore(itemMaxScore));
}

/** Maior nota entre regular e recuperação (ignora null). */
export function considerBestScore(
  regularScore: number | null,
  recoveryScore: number | null,
): number | null {
  if (regularScore === null && recoveryScore === null) return null;
  if (regularScore === null) return recoveryScore;
  if (recoveryScore === null) return regularScore;
  return Math.max(regularScore, recoveryScore);
}

/**
 * Média final em escala 0–100 a partir dos itens regulares (não recuperação).
 * (soma das notas consideradas / soma das notas máximas) * 100, arredondada para cima.
 * Itens sem nota entram como 0. Nota máxima em todos → 100.
 */
export function calculateFinalAverage(
  items: Array<{
    consideredScore: number | null;
    itemMaxScore: number;
    isRecovery: boolean;
  }>,
): number | null {
  const regular = items.filter((item) => !item.isRecovery && item.itemMaxScore > 0);
  if (regular.length === 0) {
    return null;
  }
  if (!regular.some((item) => item.consideredScore !== null)) {
    return null;
  }

  const totalMax = regular.reduce((sum, item) => sum + item.itemMaxScore, 0);
  const totalScore = regular.reduce((sum, item) => sum + (item.consideredScore ?? 0), 0);
  return Math.min(roundScore((totalScore / totalMax) * 100), 100);
}
