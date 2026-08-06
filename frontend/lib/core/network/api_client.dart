import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

/// Base URL da API. Pode ser sobrescrita em build/run via:
/// `--dart-define=API_BASE_URL=https://minha-api/api/v1`
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3333/api/v1',
);

/// Client HTTP único da aplicação. Encapsula o [Dio] e traduz falhas de
/// transporte/HTTP em [AppException], para que datasources e repositories
/// nunca precisem conhecer detalhes de `dio`/`http`.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    Future<void> Function()? onUnauthorized,
    String? baseUrl,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? kApiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            contentType: 'application/json',
          ),
        ) {
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        onUnauthorized: onUnauthorized,
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }

  final Dio dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _unwrap(() => dio.get<Map<String, dynamic>>(path, queryParameters: _clean(query)));

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    bool skipAuth = false,
  }) =>
      _unwrap(
        () => dio.post<Map<String, dynamic>>(
          path,
          data: data,
          queryParameters: _clean(query),
          options: skipAuth ? Options(extra: {'skipAuth': true}) : null,
        ),
      );

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
  }) =>
      _unwrap(() => dio.patch<Map<String, dynamic>>(path, data: data));

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
  }) =>
      _unwrap(() => dio.put<Map<String, dynamic>>(path, data: data));

  Future<void> delete(String path) async {
    try {
      await dio.delete<void>(path);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final result = <String, dynamic>{};
    for (final entry in query.entries) {
      if (entry.value != null) result[entry.key] = entry.value;
    }
    return result;
  }

  Future<Map<String, dynamic>> _unwrap(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AppException _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AppException.timeout();
    }
    if (e.type == DioExceptionType.connectionError) {
      return AppException.network();
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final error = data['error'] as Map<String, dynamic>;
      return AppException(
        code: error['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error['message'] as String? ?? 'Erro inesperado. Tente novamente.',
        statusCode: e.response?.statusCode,
        details: error['details'],
      );
    }
    if (e.response?.statusCode == 401) {
      return AppException.unauthorized();
    }
    if (e.response?.statusCode == 429) {
      return const AppException(
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Muitas requisições em pouco tempo. Aguarde um momento e tente novamente.',
        statusCode: 429,
      );
    }
    return AppException(
      code: 'UNKNOWN_ERROR',
      message: 'Erro inesperado. Tente novamente.',
      statusCode: e.response?.statusCode,
    );
  }
}
