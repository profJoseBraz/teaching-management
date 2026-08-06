-- AlterTable
ALTER TABLE "activities" ADD COLUMN "evaluated" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "activities" ADD COLUMN "evaluated_at" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "activities_teacher_id_evaluated_due_date_idx" ON "activities"("teacher_id", "evaluated", "due_date");
