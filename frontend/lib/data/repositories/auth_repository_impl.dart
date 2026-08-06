import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthDatasource _datasource;

  @override
  Future<User> login({required String email, required String password}) =>
      _datasource.login(email: email, password: password);

  @override
  Future<User> register({required String name, required String email, required String password}) =>
      _datasource.register(name: name, email: email, password: password);

  @override
  Future<void> refresh() => _datasource.refresh();

  @override
  Future<User> me() => _datasource.me();

  @override
  Future<void> logout() => _datasource.logout();

  @override
  Future<bool> isAuthenticated() => _datasource.isAuthenticated();
}
