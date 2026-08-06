import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import '../../domain/entities/user.dart';

User userFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );

/// Fala com `/auth/login`, `/auth/register`, `/auth/refresh` e `/auth/me`.
class AuthDatasource {
  AuthDatasource({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<User> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
      skipAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    await _persistTokens(data['tokens'] as Map<String, dynamic>);
    return userFromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> register({required String name, required String email, required String password}) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
      skipAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    await _persistTokens(data['tokens'] as Map<String, dynamic>);
    return userFromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Refresh token missing');
    }

    final response = await _apiClient.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      skipAuth: true,
    );
    final data = response['data'] as Map<String, dynamic>;
    await _persistTokens(data['tokens'] as Map<String, dynamic>);
  }

  Future<User> me() async {
    final response = await _apiClient.get('/auth/me');
    return userFromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> isAuthenticated() => _tokenStorage.hasToken();

  Future<void> _persistTokens(Map<String, dynamic> tokens) => _tokenStorage.saveTokens(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String,
      );
}
