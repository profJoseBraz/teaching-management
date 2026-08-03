import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<User> register({required String name, required String email, required String password});

  Future<User> me();

  Future<void> logout();

  Future<bool> isAuthenticated();
}
