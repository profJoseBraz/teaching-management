import type {
  EligibleActivity,
  GradeComposition,
  GradeCompositionCalculationMethod,
} from '../../domain/grade-composition';

export type UpsertGroupInput = {
  evaluationModelItemId: string;
  calculationMethod: GradeCompositionCalculationMethod;
  activities: Array<{
    activityId: string;
    weight?: number | null;
  }>;
};

export type UpsertGradeCompositionInput = {
  teacherId: string;
  classId: string;
  disciplineId: string;
  assessmentPeriodId: string;
  evaluationModelId: string;
  groups: UpsertGroupInput[];
};

export type CompositionSyncResult = {
  groupsAdded: number;
  groupsRemoved: number;
};

export type CalculateActivityBreakdown = {
  activityId: string;
  title: string;
  description: string | null;
  maxScore: number;
  /** null = aluno sem nota nesta atividade. */
  score: number | null;
  weight: number | null;
};

export type CalculateStudentGroupScore = {
  evaluationModelItemId: string;
  itemName: string;
  itemMaxScore: number;
  itemSortOrder: number;
  calculationMethod: GradeCompositionCalculationMethod;
  isRecovery: boolean;
  recoversItemId: string | null;
  /** Nota bruta do grupo (média das atividades). */
  convertedScore: number | null;
  /**
   * Nota considerada para o item.
   * Regular: max(nota regular, nota da recuperação vinculada).
   * Recuperação: igual à convertedScore.
   */
  consideredScore: number | null;
  /** Atividades que compõem a nota deste grupo (para modal de detalhe). */
  activities: CalculateActivityBreakdown[];
};

export type CalculateStudentRow = {
  studentId: string;
  studentName: string;
  groups: CalculateStudentGroupScore[];
  /** Média final 0–100 dos itens regulares (max → 100). */
  finalAverage: number | null;
};

export type CalculateCompositionResult = {
  compositionId: string;
  updatedAt: Date;
  students: CalculateStudentRow[];
  warnings: {
    emptyGroups: Array<{ evaluationModelItemId: string; itemName: string }>;
    ungroupedActivityCount: number;
  };
};

export interface GradeCompositionRepository {
  findByContext(
    teacherId: string,
    classId: string,
    disciplineId: string,
    assessmentPeriodId: string,
  ): Promise<GradeComposition | null>;

  findById(teacherId: string, id: string): Promise<GradeComposition | null>;

  /** Inclui soft-deleted para reativar no upsert. */
  findByContextIncludingDeleted(
    teacherId: string,
    classId: string,
    disciplineId: string,
    assessmentPeriodId: string,
  ): Promise<GradeComposition | null>;

  upsert(input: UpsertGradeCompositionInput): Promise<GradeComposition>;

  softDelete(teacherId: string, id: string): Promise<void>;

  /**
   * Garante um grupo por item ativo do modelo; remove grupos de itens soft-deleted.
   * Não altera composição FINALIZED.
   */
  syncGroupsWithModel(
    teacherId: string,
    compositionId: string,
  ): Promise<{ composition: GradeComposition; sync: CompositionSyncResult }>;

  listEligibleActivities(
    teacherId: string,
    classId: string,
    disciplineId: string,
    assessmentPeriodId: string,
  ): Promise<EligibleActivity[]>;

  loadCalculationData(
    teacherId: string,
    compositionId: string,
  ): Promise<{
    composition: GradeComposition;
    students: Array<{ id: string; name: string }>;
    scoresByStudentActivity: Map<string, Map<string, number | null>>;
    activityMaxScores: Map<string, number>;
    eligibleActivityIds: string[];
  }>;
}
