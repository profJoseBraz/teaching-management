-- Matrícula única por professor entre alunos ativos (NULL e soft-deleted não conflitam).
CREATE UNIQUE INDEX "students_teacher_id_registry_code_active_key"
ON "students" ("teacher_id", lower("registry_code"))
WHERE "registry_code" IS NOT NULL AND "deleted_at" IS NULL;
