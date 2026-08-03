-- Turma passa a ter N disciplinas (class_disciplines).
-- Aulas, conteúdos e atividades passam a carregar discipline_id.

-- 1) Join table
CREATE TABLE "class_disciplines" (
    "id" UUID NOT NULL,
    "teacher_id" UUID NOT NULL,
    "class_id" UUID NOT NULL,
    "discipline_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "class_disciplines_pkey" PRIMARY KEY ("id")
);

-- 2) Migrar vínculos atuais (1 disciplina por turma)
INSERT INTO "class_disciplines" ("id", "teacher_id", "class_id", "discipline_id", "created_at")
SELECT gen_random_uuid(), "teacher_id", "id", "discipline_id", CURRENT_TIMESTAMP
FROM "classes"
WHERE "discipline_id" IS NOT NULL;

-- 3) Adicionar discipline_id em lessons/contents/activities (nullable temporário)
ALTER TABLE "lessons" ADD COLUMN "discipline_id" UUID;
ALTER TABLE "contents" ADD COLUMN "discipline_id" UUID;
ALTER TABLE "activities" ADD COLUMN "discipline_id" UUID;

UPDATE "lessons" l
SET "discipline_id" = c."discipline_id"
FROM "classes" c
WHERE l."class_id" = c."id";

UPDATE "contents" ct
SET "discipline_id" = c."discipline_id"
FROM "classes" c
WHERE ct."class_id" = c."id";

UPDATE "activities" a
SET "discipline_id" = c."discipline_id"
FROM "classes" c
WHERE a."class_id" = c."id";

ALTER TABLE "lessons" ALTER COLUMN "discipline_id" SET NOT NULL;
ALTER TABLE "contents" ALTER COLUMN "discipline_id" SET NOT NULL;
ALTER TABLE "activities" ALTER COLUMN "discipline_id" SET NOT NULL;

-- 4) Remover discipline_id da turma
ALTER TABLE "classes" DROP CONSTRAINT "classes_discipline_id_fkey";
DROP INDEX IF EXISTS "classes_discipline_id_idx";
DROP INDEX IF EXISTS "classes_teacher_id_academic_year_id_course_id_discipline_id_name_key";
ALTER TABLE "classes" DROP COLUMN "discipline_id";

CREATE UNIQUE INDEX "classes_teacher_id_academic_year_id_course_id_name_key"
ON "classes"("teacher_id", "academic_year_id", "course_id", "name");

-- 5) Índices e FKs do join
CREATE UNIQUE INDEX "class_disciplines_class_id_discipline_id_key"
ON "class_disciplines"("class_id", "discipline_id");
CREATE INDEX "class_disciplines_teacher_id_idx" ON "class_disciplines"("teacher_id");
CREATE INDEX "class_disciplines_class_id_idx" ON "class_disciplines"("class_id");
CREATE INDEX "class_disciplines_discipline_id_idx" ON "class_disciplines"("discipline_id");

ALTER TABLE "class_disciplines"
  ADD CONSTRAINT "class_disciplines_teacher_id_fkey"
  FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "class_disciplines"
  ADD CONSTRAINT "class_disciplines_class_id_fkey"
  FOREIGN KEY ("class_id") REFERENCES "classes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "class_disciplines"
  ADD CONSTRAINT "class_disciplines_discipline_id_fkey"
  FOREIGN KEY ("discipline_id") REFERENCES "disciplines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- 6) FKs e índices em lessons/contents/activities
CREATE INDEX "lessons_class_id_discipline_id_idx" ON "lessons"("class_id", "discipline_id");
CREATE INDEX "lessons_discipline_id_idx" ON "lessons"("discipline_id");
ALTER TABLE "lessons"
  ADD CONSTRAINT "lessons_discipline_id_fkey"
  FOREIGN KEY ("discipline_id") REFERENCES "disciplines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE INDEX "contents_class_id_discipline_id_idx" ON "contents"("class_id", "discipline_id");
CREATE INDEX "contents_discipline_id_idx" ON "contents"("discipline_id");
ALTER TABLE "contents"
  ADD CONSTRAINT "contents_discipline_id_fkey"
  FOREIGN KEY ("discipline_id") REFERENCES "disciplines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE INDEX "activities_class_id_discipline_id_idx" ON "activities"("class_id", "discipline_id");
CREATE INDEX "activities_discipline_id_idx" ON "activities"("discipline_id");
ALTER TABLE "activities"
  ADD CONSTRAINT "activities_discipline_id_fkey"
  FOREIGN KEY ("discipline_id") REFERENCES "disciplines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
