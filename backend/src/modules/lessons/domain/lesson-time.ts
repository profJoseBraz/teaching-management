import { ValidationError } from '../../../shared/domain/errors';

const TIME_PATTERN = /^([0-1]\d|2[0-3]):([0-5]\d)$/;

export function isValidTimeFormat(time: string): boolean {
  return TIME_PATTERN.test(time);
}

function timeToMinutes(time: string): number {
  const match = TIME_PATTERN.exec(time);
  if (!match) {
    throw new ValidationError(`Invalid time format: "${time}". Expected HH:mm`);
  }
  const [, hours, minutes] = match;
  return Number(hours) * 60 + Number(minutes);
}

/** Regra de domínio: horário de término deve ser estritamente posterior ao início. */
export function assertEndTimeAfterStartTime(startTime: string, endTime: string): void {
  if (timeToMinutes(endTime) <= timeToMinutes(startTime)) {
    throw new ValidationError('endTime must be after startTime');
  }
}
