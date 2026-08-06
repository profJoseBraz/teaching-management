-- Backfill: lançamentos sem período → 2º período do ano letivo da turma (sort_order = 1).
-- Aulas/atividades antigas ficaram com assessment_period_id NULL após a introdução do filtro.

UPDATE lessons AS l
SET assessment_period_id = ap.id
FROM classes AS c
INNER JOIN assessment_periods AS ap
  ON ap.academic_year_id = c.academic_year_id
 AND ap.deleted_at IS NULL
 AND ap.sort_order = 1
WHERE l.class_id = c.id
  AND l.assessment_period_id IS NULL
  AND l.deleted_at IS NULL;

UPDATE contents AS ct
SET assessment_period_id = ap.id
FROM classes AS c
INNER JOIN assessment_periods AS ap
  ON ap.academic_year_id = c.academic_year_id
 AND ap.deleted_at IS NULL
 AND ap.sort_order = 1
WHERE ct.class_id = c.id
  AND ct.assessment_period_id IS NULL
  AND ct.deleted_at IS NULL;

UPDATE activities AS a
SET assessment_period_id = ap.id
FROM classes AS c
INNER JOIN assessment_periods AS ap
  ON ap.academic_year_id = c.academic_year_id
 AND ap.deleted_at IS NULL
 AND ap.sort_order = 1
WHERE a.class_id = c.id
  AND a.assessment_period_id IS NULL
  AND a.deleted_at IS NULL;
