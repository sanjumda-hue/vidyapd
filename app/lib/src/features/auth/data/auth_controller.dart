import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../domain/auth_user.dart';
import 'auth_repository.dart';

/// null = signed out. Loading while the stored token is checked on start.
class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    _restore();
  }

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  /// A stored token may have expired while the app was closed, so it is only
  /// trusted once /auth/me accepts it.
  Future<void> _restore() async {
    final token = await _repo.readToken();
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }
    _ref.read(apiClientProvider).token = token;
    try {
      state = AsyncValue.data(await _repo.me());
    } catch (_) {
      await _repo.writeToken(null);
      _ref.read(apiClientProvider).token = null;
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signIn(String email, String password) => _run(
        () => _repo.login(email, password),
      );

  Future<void> register(String email, String password, String? fullName) => _run(
        () => _repo.register(email, password, fullName),
      );

  Future<void> _run(Future<AuthResult> Function() call) async {
    state = const AsyncValue.loading();
    try {
      final result = await call();
      await _repo.writeToken(result.token);
      _ref.read(apiClientProvider).token = result.token;
      state = AsyncValue.data(result.user);
    } catch (e, st) {
      // Stay signed out, but surface why.
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _repo.writeToken(null);
    _ref.read(apiClientProvider).token = null;
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>(
  (ref) => AuthController(ref),
);

/// Convenience for widgets that only care whether someone is signed in.
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider).valueOrNull != null,
);
