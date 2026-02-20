import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client_provider.dart';
import '../repo/auth_repository.dart';

class AuthActionState {
  const AuthActionState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;

  AuthActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthActionState> {
  AuthController(this._repo) : super(const AuthActionState());

  final AuthRepository _repo;

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.signInWithPassword(email: email.trim(), password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sign in.',
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.signUpWithPassword(email: email.trim(), password: password);
      await _repo.upsertProfile(displayName: displayName);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sign up.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  Future<bool> requestPasswordReset({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.requestPasswordReset(email.trim());
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to send password reset email.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthActionState>((ref) {
      final repo = ref.watch(authRepositoryProvider);
      return AuthController(repo);
    });
