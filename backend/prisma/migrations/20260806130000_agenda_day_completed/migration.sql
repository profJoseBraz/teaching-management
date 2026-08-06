-- AlterTable
ALTER TABLE "agenda_days" ADD COLUMN "completed" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX "agenda_days_teacher_id_completed_idx" ON "agenda_days"("teacher_id", "completed");
