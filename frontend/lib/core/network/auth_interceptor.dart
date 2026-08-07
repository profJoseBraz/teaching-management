import 'dart:async';

import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Anexa `Authorization: Bearer <accessToken>` e, em `401`, tenta renovar a
/// sessão com o refresh token (single-flight) antes de forçar logout.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    this.onUnauthorized,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Future<void> Function()? onUnauthorized;

  Completer<void>? _refreshCompleter;

  static bool _isAuthPublicPath(String path) {
    final normalized = path.split('?').first;
    return normalized.endsWith('/auth/login') ||
        normalized.endsWith('/auth/register') ||
        normalized.endsWith('/auth/refresh');
  }

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
    final status = err.response?.statusCode;
    final options = err.requestOptions;

    if (status != 401 ||
        options.extra['skipAuth'] == true ||
        options.extra['retriedAfterRefresh'] == true ||
        _isAuthPublicPath(options.path)) {
      if (status == 401 && !_isAuthPublicPath(options.path)) {
        await _forceLogout();
      }
      handler.next(err);
      return;
    }

    try {
      await _refreshTokens();
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw StateError('Access token missing after refresh');
      }

      final retryOptions = options.copyWith(
        headers: {
          ...options.headers,
          'Authorization': 'Bearer $accessToken',
        },
        extra: {
          ...options.extra,
          'retriedAfterRefresh': true,
        },
      );

      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (refreshError) {
      // Só derruba a sessão quando o refresh for rejeitado (token inválido/expirado).
      // Falha de rede/timeout não deve apagar tokens válidos.
      if (_shouldForceLogoutAfterRefreshFailure(refreshError)) {
        await _forceLogout();
      }
      handler.next(err);
    }
  }

  bool _shouldForceLogoutAfterRefreshFailure(Object error) {
    if (error is StateError) {
      return true;
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      return status == 401 || status == 403;
    }
    return false;
  }

  Future<void> _forceLogout() async {
    await _tokenStorage.clear();
    await onUnauthorized?.call();
  }

  /// Uma única renovação compartilhada entre 401s concorrentes.
  Future<void> _refreshTokens() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;

    () async {
      try {
        final refreshToken = await _tokenStorage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          throw StateError('Refresh token missing');
        }

        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'skipAuth': true}),
        );

        final data = response.data?['data'] as Map<String, dynamic>?;
        final tokens = data?['tokens'] as Map<String, dynamic>?;
        final accessToken = tokens?['accessToken'] as String?;
        final nextRefresh = tokens?['refreshToken'] as String?;

        if (accessToken == null ||
            accessToken.isEmpty ||
            nextRefresh == null ||
            nextRefresh.isEmpty) {
          throw StateError('Invalid refresh response');
        }

        await _tokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: nextRefresh,
        );
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_refreshCompleter, completer)) {
          _refreshCompleter = null;
        }
      }
    }();

    return completer.future;
  }
}
