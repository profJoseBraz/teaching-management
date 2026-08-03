export type HttpErrorBody = {
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
};

export function toErrorBody(code: string, message: string, details?: unknown): HttpErrorBody {
  return {
    error: {
      code,
      message,
      ...(details !== undefined ? { details } : {}),
    },
  };
}
