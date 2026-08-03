import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Anexa o `Authorization: Bearer <token>` em toda requisição autenticada e
/// notifica a aplicação quando o backend responde 401 (sessão expirada),
/// para que o estado de autenticação seja limpo e o [go_router] redirecione
/// para a tela de login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    this.onUnauthorized,
  }) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;
  final Future<void> Function()? onUnauthorized;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final skipAuth = options.extra['skipAuth'] == true;
    if (!skipAuth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _tokenStorage.clear();
      await onUnauthorized?.call();
    }
    handler.next(err);
  }
}
