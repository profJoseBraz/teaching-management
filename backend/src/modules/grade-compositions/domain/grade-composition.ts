export type GradeCompositionCalculationMethod = 'SIMPLE_AVERAGE' | 'WEIGHTED_AVERAGE';
export type GradeCompositionStatus = 'DRAFT' | 'FINALIZED';

export type GradeCompositionActivity = {
  id: string;
  teacherId: string;
  gradeCompositionGroupId: string;
  activityId: string;
  weight: number | null;
  createdAt: Date;
  updatedAt: Date;
  activityTitle?: string;
  activityDescription?: string | null;
  activityMaxScore?: number;
};

export type GradeCompositionGroup = {
  id: string;
  teacherId: string;
  gradeCompositionId: string;
  evaluationModelItemId: string;
  calculationMethod: GradeCompositionCalculationMethod;
  createdAt: Date;
  updatedAt: Date;
  /** Ordem e metadados vindos do item do modelo (não snapshot). */
  itemName: string;
  itemMaxScore: number;
  itemSortOrder: number;
  isRecovery: boolean;
  recoversItemId: string | null;
  activities: GradeCompositionActivity[];
};

export type GradeComposition = {
  id: string;
  teacherId: string;
  classId: string;
  disciplineId: string;
  assessmentPeriodId: string;
  evaluationModelId: string;
  status: GradeCompositionStatus;
  finalizedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
  evaluationModelName?: string;
  groups: GradeCompositionGroup[];
};

export type EligibleActivity = {
  id: string;
  title: string;
  maxScore: number;
  tag: string | null;
  dueDate: Date;
};
