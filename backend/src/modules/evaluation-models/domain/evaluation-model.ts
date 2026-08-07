export type EvaluationModelItem = {
  id: string;
  teacherId: string;
  evaluationModelId: string;
  name: string;
  maxScore: number;
  sortOrder: number;
  isRecovery: boolean;
  /** Quando isRecovery, aponta para o item regular recuperado. */
  recoversItemId: string | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type EvaluationModel = {
  id: string;
  teacherId: string;
  name: string;
  description: string | null;
  isActive: boolean;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  items: EvaluationModelItem[];
};
