-- AlterTable
ALTER TABLE "evaluation_model_items" ADD COLUMN "is_recovery" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "evaluation_model_items" ADD COLUMN "recovers_item_id" UUID;

-- CreateIndex
CREATE INDEX "evaluation_model_items_recovers_item_id_idx" ON "evaluation_model_items"("recovers_item_id");

-- AddForeignKey
ALTER TABLE "evaluation_model_items" ADD CONSTRAINT "evaluation_model_items_recovers_item_id_fkey" FOREIGN KEY ("recovers_item_id") REFERENCES "evaluation_model_items"("id") ON DELETE SET NULL ON UPDATE CASCADE;
