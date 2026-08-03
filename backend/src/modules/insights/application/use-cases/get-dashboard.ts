import type { AttentionItem, AttentionSeverity } from '../../domain/attention-item';
import type { GetAttentionItemsInput, GetAttentionItemsUseCase } from './get-attention-items';

export type DashboardSummary = {
  totalAttentionItems: number;
  totalPendingActions: number;
  bySeverity: Record<AttentionSeverity, number>;
};

export type DashboardResult = {
  attentionItems: AttentionItem[];
  summary: DashboardSummary;
};

function buildSummary(attentionItems: AttentionItem[]): DashboardSummary {
  return {
    totalAttentionItems: attentionItems.length,
    totalPendingActions: attentionItems.reduce((sum, item) => sum + item.count, 0),
    bySeverity: {
      high: attentionItems.filter((item) => item.severity === 'high').length,
      medium: attentionItems.filter((item) => item.severity === 'medium').length,
      low: attentionItems.filter((item) => item.severity === 'low').length,
    },
  };
}

/** Orquestra o Insights Engine para a tela principal — nunca acessa Prisma diretamente. */
export class GetDashboardUseCase {
  constructor(private readonly getAttentionItems: GetAttentionItemsUseCase) {}

  async execute(input: GetAttentionItemsInput): Promise<DashboardResult> {
    const attentionItems = await this.getAttentionItems.execute(input);
    return {
      attentionItems,
      summary: buildSummary(attentionItems),
    };
  }
}
