-- Atividade ↔ Disciplinas (N:N). Migra o discipline_id legado e remove a coluna.

CREATE TABLE "activity_disciplines" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "teacher_id" UUID NOT NULL,
    "activity_id" UUID NOT NULL,
    "discipline_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "activity_disciplines_pkey" PRIMARY KEY ("id")
);

INSERT INTO "activity_disciplines" ("id", "teacher_id", "activity_id", "discipline_id", "created_at", "deleted_at")
SELECT gen_random_uuid(), a."teacher_id", a."id", a."discipline_id", CURRENT_TIMESTAMP, a."deleted_at"
FROM "activities" a
WHERE a."discipline_id" IS NOT NULL;

ALTER TABLE "activities" DROP CONSTRAINT IF EXISTS "activities_discipline_id_fkey";
DROP INDEX IF EXISTS "activities_class_id_discipline_id_idx";
DROP INDEX IF EXISTS "activities_discipline_id_idx";
ALTER TABLE "activities" DROP COLUMN "discipline_id";

CREATE UNIQUE INDEX "activity_disciplines_activity_id_discipline_id_key"
  ON "activity_disciplines"("activity_id", "discipline_id");
CREATE INDEX "activity_disciplines_teacher_id_idx" ON "activity_disciplines"("teacher_id");
CREATE INDEX "activity_disciplines_activity_id_idx" ON "activity_disciplines"("activity_id");
CREATE INDEX "activity_disciplines_discipline_id_idx" ON "activity_disciplines"("discipline_id");

ALTER TABLE "activity_disciplines"
  ADD CONSTRAINT "activity_disciplines_teacher_id_fkey"
  FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "activity_disciplines"
  ADD CONSTRAINT "activity_disciplines_activity_id_fkey"
  FOREIGN KEY ("activity_id") REFERENCES "activities"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "activity_disciplines"
  ADD CONSTRAINT "activity_disciplines_discipline_id_fkey"
  FOREIGN KEY ("discipline_id") REFERENCES "disciplines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
