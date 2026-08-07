import { describe, expect, it } from 'vitest';
import {
  calculateFinalAverage,
  calculateGroupConvertedScore,
  considerBestScore,
  normalizeActivityScore,
  roundScore,
} from '../../src/modules/grade-compositions/domain/grade-calculator';

describe('grade-calculator', () => {
  it('normalizes activity scores to a 0–100 scale', () => {
    expect(normalizeActivityScore(8, 10)).toBe(80);
    expect(normalizeActivityScore(0, 100)).toBe(0);
    expect(normalizeActivityScore(50, 50)).toBe(100);
  });

  it('rounds converted scores up to the next integer', () => {
    expect(roundScore(18.4)).toBe(19);
    expect(roundScore(36)).toBe(36);
    expect(roundScore(0.1)).toBe(1);
    expect(roundScore(0)).toBe(0);
  });

  it('returns null when the student has no graded activities at all', () => {
    expect(
      calculateGroupConvertedScore(
        'SIMPLE_AVERAGE',
        [
          { score: null, activityMaxScore: 100, weight: null },
          { score: null, activityMaxScore: 10, weight: null },
        ],
        10,
      ),
    ).toBeNull();
  });

  it('treats missing grades as zero and ceils the result', () => {
    // (92 + 0) / 2 = 46% of 40 = 18.4 → 19
    expect(
      calculateGroupConvertedScore(
        'SIMPLE_AVERAGE',
        [
          { score: 92, activityMaxScore: 100, weight: null },
          { score: null, activityMaxScore: 100, weight: null },
        ],
        40,
      ),
    ).toBe(19);
  });

  it('computes a weighted average counting missing as zero and ceils', () => {
    // (100*2 + 0*1) / 3 = 66.666...% of 10 = 6.666... → 7
    expect(
      calculateGroupConvertedScore(
        'WEIGHTED_AVERAGE',
        [
          { score: 10, activityMaxScore: 10, weight: 2 },
          { score: null, activityMaxScore: 10, weight: 1 },
        ],
        10,
      ),
    ).toBe(7);
  });

  it('treats an explicit zero as a real grade', () => {
    expect(
      calculateGroupConvertedScore(
        'SIMPLE_AVERAGE',
        [{ score: 0, activityMaxScore: 100, weight: null }],
        10,
      ),
    ).toBe(0);
  });

  it('keeps exact integers without bumping them', () => {
    // (80+100)/2 = 90% of 40 = 36
    expect(
      calculateGroupConvertedScore(
        'SIMPLE_AVERAGE',
        [
          { score: 80, activityMaxScore: 100, weight: null },
          { score: 100, activityMaxScore: 100, weight: null },
        ],
        40,
      ),
    ).toBe(36);
  });

  it('considers the best score between regular and recovery', () => {
    expect(considerBestScore(40, 28)).toBe(40);
    expect(considerBestScore(30, 35)).toBe(35);
    expect(considerBestScore(40, null)).toBe(40);
    expect(considerBestScore(null, 28)).toBe(28);
    expect(considerBestScore(null, null)).toBeNull();
  });

  it('computes final average on a 0–100 scale from regular items', () => {
    expect(
      calculateFinalAverage([
        { consideredScore: 40, itemMaxScore: 40, isRecovery: false },
        { consideredScore: 40, itemMaxScore: 40, isRecovery: false },
        { consideredScore: 20, itemMaxScore: 40, isRecovery: true },
      ]),
    ).toBe(100);

    expect(
      calculateFinalAverage([
        { consideredScore: 40, itemMaxScore: 40, isRecovery: false },
        { consideredScore: 20, itemMaxScore: 40, isRecovery: false },
      ]),
    ).toBe(75);

    expect(
      calculateFinalAverage([
        { consideredScore: null, itemMaxScore: 40, isRecovery: false },
        { consideredScore: null, itemMaxScore: 40, isRecovery: false },
      ]),
    ).toBeNull();
  });
});
