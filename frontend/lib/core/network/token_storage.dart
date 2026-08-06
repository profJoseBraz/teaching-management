import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazena tokens JWT de forma segura (Keychain/Keystore/DPAPI conforme a plataforma).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'gd_access_token';
  static const _refreshTokenKey = 'gd_refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Há sessão se existir access ou refresh (access pode estar expirado).
  Future<bool> hasToken() async {
    final access = await readAccessToken();
    if (access != null && access.isNotEmpty) return true;
    final refresh = await readRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }
}
