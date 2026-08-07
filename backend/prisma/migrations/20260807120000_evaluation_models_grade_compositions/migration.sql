-- CreateEnum
CREATE TYPE "GradeCompositionCalculationMethod" AS ENUM ('SIMPLE_AVERAGE', 'WEIGHTED_AVERAGE');

-- CreateEnum
CREATE TYPE "GradeCompositionStatus" AS ENUM ('DRAFT', 'FINALIZED');

-- CreateTable
CREATE TABLE "evaluation_models" (
    "id" UUID NOT NULL,
    "teacher_id" UUID NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "evaluation_models_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "evaluation_model_items" (
    "id" UUID NOT NULL,
    "teacher_id" UUID NOT NULL,
    "evaluation_model_id" UUID NOT NULL,
    "name" VARCHAR(160) NOT NULL,
    "max_score" DECIMAL(6,2) NOT NULL DEFAULT 100,
    "sort_order" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "evaluation_model_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "grade_compositions" (
    "id" UUID NOT NULL,
    "teacher_id" UUID NOT NULL,
    "class_id" UUID NOT NULL,
    "discipline_id" UUID NOT NULL,
    "assessment_period_id" UUID NOT NULL,
    "evaluation_model_id" UUID NOT NULL,
    "status" "GradeCompositionStatus" NOT NULL DEFAULT 'DRAFT',
    "finalized_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "grade_compositions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "grade_composition_groups" (
    "id" UUID NOT NULL,
    "teacher_id" UUID NOT NULL,
    "grade_composition_id" UUID NOT NULL,
    "evaluation_model_item_id" UUID NOT NULL,
    "calculation_method" "GradeCompositionCalculationMethod" NOT NULL DEFAULT 'SIMPLE_AVERAGE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "grade_composition_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "grade_composition_activities" (
    "id" UUID NOT NULL,
    "teacher_id" UUID NOT NULL,
    "grade_composition_group_id" UUID NOT NULL,
    "activity_id" UUID NOT NULL,
    "weight" DECIMAL(8,4),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "grade_composition_activities_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "evaluation_models_teacher_id_idx" ON "evaluation_models"("teacher_id");
CREATE INDEX "evaluation_models_teacher_id_is_active_idx" ON "evaluation_models"("teacher_id", "is_active");
CREATE INDEX "evaluation_models_teacher_id_sort_order_idx" ON "evaluation_models"("teacher_id", "sort_order");

CREATE INDEX "evaluation_model_items_teacher_id_idx" ON "evaluation_model_items"("teacher_id");
CREATE INDEX "evaluation_model_items_evaluation_model_id_sort_order_idx" ON "evaluation_model_items"("evaluation_model_id", "sort_order");

CREATE UNIQUE INDEX "grade_compositions_class_id_discipline_id_assessment_period_id_key" ON "grade_compositions"("class_id", "discipline_id", "assessment_period_id");
CREATE INDEX "grade_compositions_teacher_id_idx" ON "grade_compositions"("teacher_id");
CREATE INDEX "grade_compositions_class_id_idx" ON "grade_compositions"("class_id");
CREATE INDEX "grade_compositions_discipline_id_idx" ON "grade_compositions"("discipline_id");
CREATE INDEX "grade_compositions_assessment_period_id_idx" ON "grade_compositions"("assessment_period_id");
CREATE INDEX "grade_compositions_evaluation_model_id_idx" ON "grade_compositions"("evaluation_model_id");
CREATE INDEX "grade_compositions_teacher_id_status_idx" ON "grade_compositions"("teacher_id", "status");

CREATE UNIQUE INDEX "grade_composition_groups_grade_composition_id_evaluation_model_item_id_key" ON "grade_composition_groups"("grade_composition_id", "evaluation_model_item_id");
CREATE INDEX "grade_composition_groups_teacher_id_idx" ON "grade_composition_groups"("teacher_id");
CREATE INDEX "grade_composition_groups_grade_composition_id_idx" ON "grade_composition_groups"("grade_composition_id");
CREATE INDEX "grade_composition_groups_evaluation_model_item_id_idx" ON "grade_composition_groups"("evaluation_model_item_id");

CREATE UNIQUE INDEX "grade_composition_activities_grade_composition_group_id_activity_id_key" ON "grade_composition_activities"("grade_composition_group_id", "activity_id");
CREATE INDEX "grade_composition_activities_teacher_id_idx" ON "grade_composition_activities"("teacher_id");
CREATE INDEX "grade_composition_activities_grade_composition_group_id_idx" ON "grade_composition_activities"("grade_composition_group_id");
CREATE INDEX "grade_composition_activities_activity_id_idx" ON "grade_composition_activities"("activity_id");

-- AddForeignKey
ALTER TABLE "evaluation_models" ADD CONSTRAINT "evaluation_models_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "evaluation_model_items" ADD CONSTRAINT "evaluation_model_items_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "evaluation_model_items" ADD CONSTRAINT "evaluation_model_items_evaluation_model_id_fkey" FOREIGN KEY ("evaluation_model_id") REFERENCES "evaluation_models"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "grade_compositions" ADD CONSTRAINT "grade_compositions_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "grade_compositions" ADD CONSTRAINT "grade_compositions_class_id_fkey" FOREIGN KEY ("class_id") REFERENCES "classes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "grade_compositions" ADD CONSTRAINT "grade_compositions_discipline_id_fkey" FOREIGN KEY ("discipline_id") REFERENCES "disciplines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "grade_compositions" ADD CONSTRAINT "grade_compositions_assessment_period_id_fkey" FOREIGN KEY ("assessment_period_id") REFERENCES "assessment_periods"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "grade_compositions" ADD CONSTRAINT "grade_compositions_evaluation_model_id_fkey" FOREIGN KEY ("evaluation_model_id") REFERENCES "evaluation_models"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "grade_composition_groups" ADD CONSTRAINT "grade_composition_groups_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "grade_composition_groups" ADD CONSTRAINT "grade_composition_groups_grade_composition_id_fkey" FOREIGN KEY ("grade_composition_id") REFERENCES "grade_compositions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "grade_composition_groups" ADD CONSTRAINT "grade_composition_groups_evaluation_model_item_id_fkey" FOREIGN KEY ("evaluation_model_item_id") REFERENCES "evaluation_model_items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "grade_composition_activities" ADD CONSTRAINT "grade_composition_activities_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "grade_composition_activities" ADD CONSTRAINT "grade_composition_activities_grade_composition_group_id_fkey" FOREIGN KEY ("grade_composition_group_id") REFERENCES "grade_composition_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "grade_composition_activities" ADD CONSTRAINT "grade_composition_activities_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "activities"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
