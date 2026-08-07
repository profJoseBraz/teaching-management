import { ValidationError } from '../../../shared/domain/errors';
import type { EvaluationModelItem } from '../domain/evaluation-model';

export function assertRecoveryLink(input: {
  isRecovery: boolean;
  recoversItemId: string | null | undefined;
  itemId?: string;
  modelItems: EvaluationModelItem[];
}): void {
  if (!input.isRecovery) {
    if (input.recoversItemId) {
      throw new ValidationError('recoversItemId is only allowed when the item is a recovery');
    }
    return;
  }

  if (!input.recoversItemId) {
    throw new ValidationError('Recovery items must reference the regular item they recover');
  }

  if (input.itemId && input.recoversItemId === input.itemId) {
    throw new ValidationError('A recovery item cannot recover itself');
  }

  const target = input.modelItems.find((item) => item.id === input.recoversItemId);
  if (!target) {
    throw new ValidationError('Recovered item was not found in this evaluation model');
  }
  if (target.isRecovery) {
    throw new ValidationError('A recovery item cannot recover another recovery item');
  }

  const alreadyLinked = input.modelItems.find(
    (item) =>
      item.isRecovery &&
      item.recoversItemId === input.recoversItemId &&
      item.id !== input.itemId,
  );
  if (alreadyLinked) {
    throw new ValidationError('This regular item already has a recovery item');
  }
}
