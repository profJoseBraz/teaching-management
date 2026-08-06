-- Renomeia agenda_days → agenda_notes e remove unicidade por data
-- (várias anotações distintas podem compartilhar a mesma data).

ALTER TABLE "agenda_days" RENAME TO "agenda_notes";

ALTER INDEX IF EXISTS "agenda_days_pkey" RENAME TO "agenda_notes_pkey";
ALTER INDEX IF EXISTS "agenda_days_teacher_id_idx" RENAME TO "agenda_notes_teacher_id_idx";
ALTER INDEX IF EXISTS "agenda_days_teacher_id_date_idx" RENAME TO "agenda_notes_teacher_id_date_idx";
ALTER INDEX IF EXISTS "agenda_days_teacher_id_completed_idx" RENAME TO "agenda_notes_teacher_id_completed_idx";

DROP INDEX IF EXISTS "agenda_days_teacher_id_date_key";

ALTER TABLE "agenda_notes" RENAME CONSTRAINT "agenda_days_teacher_id_fkey" TO "agenda_notes_teacher_id_fkey";
