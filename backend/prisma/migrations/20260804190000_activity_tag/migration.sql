-- Tag opcional para agrupar atividades (rótulo livre reutilizável).
ALTER TABLE "activities" ADD COLUMN "tag" VARCHAR(80);

CREATE INDEX "activities_teacher_id_tag_idx" ON "activities"("teacher_id", "tag");
CREATE INDEX "activities_class_id_tag_idx" ON "activities"("class_id", "tag");
