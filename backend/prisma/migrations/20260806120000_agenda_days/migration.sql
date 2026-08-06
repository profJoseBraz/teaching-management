-- CreateTable
CREATE TABLE "agenda_days" (
    "id" UUID NOT NULL,
    "teacher_id" UUID NOT NULL,
    "date" DATE NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "agenda_days_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "agenda_days_teacher_id_idx" ON "agenda_days"("teacher_id");

-- CreateIndex
CREATE INDEX "agenda_days_teacher_id_date_idx" ON "agenda_days"("teacher_id", "date");

-- CreateIndex
CREATE UNIQUE INDEX "agenda_days_teacher_id_date_key" ON "agenda_days"("teacher_id", "date");

-- AddForeignKey
ALTER TABLE "agenda_days" ADD CONSTRAINT "agenda_days_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
