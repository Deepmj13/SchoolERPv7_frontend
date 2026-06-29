import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_admin/core/api/api_client.dart';
import 'package:school_erp_admin/core/storage/storage_interface.dart';
import 'package:school_erp_admin/core/storage/storage_service.dart';
import 'package:school_erp_admin/features/auth/data/auth_repository.dart';
import 'package:school_erp_admin/features/auth/domain/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final client = ApiClient(storage: storage);
  ref.onDispose(client.dispose);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthStateNotifier(authRepository, storage);
});

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final StorageInterface _storage;

  AuthStateNotifier(this._authRepository, this._storage)
      : super(const AuthState()) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await _storage.getToken();
    if (token != null) {
      final userData = await _storage.getUser();
      if (userData != null) {
        final user = UserModel.fromJson(userData);
        if (user.isAdmin) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
          );
          return;
        }
      }
      await _storage.clear();
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );

    try {
      final user = await _authRepository.login(email, password);

      if (!user.isAdmin) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Access denied. Admin credentials required.',
        );
        return;
      }

      await _storage.saveToken(user.token);
      await _storage.saveUser(user.toJson());

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Connection failed. Please check your network.',
      );
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }


}
