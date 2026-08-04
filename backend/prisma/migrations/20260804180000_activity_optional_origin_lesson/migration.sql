-- Activity.originLessonId torna-se opcional: atividade pode existir sem aula de origem.
ALTER TABLE "activities" ALTER COLUMN "origin_lesson_id" DROP NOT NULL;
