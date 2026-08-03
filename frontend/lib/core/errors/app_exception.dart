/// Exceção de domínio para erros vindos da API ou de validações locais.
///
/// Padronizada a partir do contrato de erro do backend:
/// `{ error: { code, message, details? } }`.
class AppException implements Exception {
  const AppException({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode,
    this.details,
  });

  factory AppException.network() => const AppException(
        code: 'NETWORK_ERROR',
        message: 'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );

  factory AppException.timeout() => const AppException(
        code: 'TIMEOUT',
        message: 'O servidor demorou para responder. Tente novamente.',
      );

  factory AppException.unauthorized([String? message]) => AppException(
        code: 'UNAUTHENTICATED',
        message: message ?? 'Sessão expirada. Faça login novamente.',
        statusCode: 401,
      );

  final String code;
  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => 'AppException($code): $message';
}
