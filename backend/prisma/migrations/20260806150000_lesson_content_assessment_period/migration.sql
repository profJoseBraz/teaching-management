-- AlterTable
ALTER TABLE "lessons" ADD COLUMN "assessment_period_id" UUID;

-- AlterTable
ALTER TABLE "contents" ADD COLUMN "assessment_period_id" UUID;

-- CreateIndex
CREATE INDEX "lessons_class_id_assessment_period_id_idx" ON "lessons"("class_id", "assessment_period_id");

-- CreateIndex
CREATE INDEX "lessons_assessment_period_id_idx" ON "lessons"("assessment_period_id");

-- CreateIndex
CREATE INDEX "contents_class_id_assessment_period_id_idx" ON "contents"("class_id", "assessment_period_id");

-- CreateIndex
CREATE INDEX "contents_assessment_period_id_idx" ON "contents"("assessment_period_id");

-- AddForeignKey
ALTER TABLE "lessons" ADD CONSTRAINT "lessons_assessment_period_id_fkey" FOREIGN KEY ("assessment_period_id") REFERENCES "assessment_periods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "contents" ADD CONSTRAINT "contents_assessment_period_id_fkey" FOREIGN KEY ("assessment_period_id") REFERENCES "assessment_periods"("id") ON DELETE SET NULL ON UPDATE CASCADE;
