import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Sobrescrito em `main.dart` após `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider deve ser sobrescrito em main.dart');
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Ponte simples e sem tipagem cíclica entre o [ApiClient] (infraestrutura)
/// e o [AuthNotifier] (estado): evita uma dependência circular no grafo de
/// providers (`apiClientProvider` -> `authNotifierProvider` -> ... ->
/// `apiClientProvider`) que o analisador do Dart não consegue resolver.
class SessionEvents {
  VoidCallback? onUnauthorized;
}

final sessionEventsProvider = Provider<SessionEvents>((ref) => SessionEvents());

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final events = ref.watch(sessionEventsProvider);
  return ApiClient(
    tokenStorage: tokenStorage,
    onUnauthorized: () async => events.onUnauthorized?.call(),
  );
});

final authDatasourceProvider = Provider<AuthDatasource>(
  (ref) => AuthDatasource(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authDatasourceProvider)),
);

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage});

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, User? user, String? errorMessage}) => AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
      );

  static const initial = AuthState(status: AuthStatus.checking);
}

/// Controla o estado de autenticação e serve de fonte de verdade para o
/// redirect do [go_router] (via [routerRefreshProvider]).
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository, SessionEvents events) : super(AuthState.initial) {
    events.onUnauthorized = forceLogout;
    _bootstrap();
  }

  final AuthRepository _repository;

  Future<void> _bootstrap() async {
    final hasToken = await _repository.isAuthenticated();
    if (!hasToken) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repository.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _repository.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.checking, errorMessage: null);
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on AppException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message);
      return false;
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Erro inesperado ao entrar. Tente novamente.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Chamado pelo interceptor HTTP quando a API responde 401.
  void forceLogout() {
    if (state.status != AuthStatus.unauthenticated) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Sessão expirada. Faça login novamente.',
      );
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref.watch(sessionEventsProvider)),
);

/// Ponte entre o estado reativo do Riverpod e o `refreshListenable` do
/// go_router (que espera um [Listenable] clássico).
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
