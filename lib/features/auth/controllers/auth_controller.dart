import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client_provider.dart';
import '../repo/auth_repository.dart';

class AuthActionState {
  const AuthActionState({
    this.isLoading = false,
    this.errorMessage,
    this.sentEmail,
    this.pendingDisplayName,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? sentEmail;
  final String? pendingDisplayName;

  AuthActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? sentEmail,
    String? pendingDisplayName,
    bool clearError = false,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      sentEmail: sentEmail ?? this.sentEmail,
      pendingDisplayName: pendingDisplayName ?? this.pendingDisplayName,
    );
  }
}

class AuthController extends StateNotifier<AuthActionState> {
  AuthController(this._repo) : super(const AuthActionState());

  final AuthRepository _repo;

  Future<void> sendOtp({
    required String email,
    required bool shouldCreateUser,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.sendOtp(email: email.trim(), shouldCreateUser: shouldCreateUser);
      state = state.copyWith(
        isLoading: false,
        sentEmail: email.trim(),
        pendingDisplayName: displayName,
      );
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong.');
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (token.trim().length != 6) {
        state = state.copyWith(isLoading: false, errorMessage: 'Enter the 6-digit code.');
        return false;
      }

      await _repo.verifyOtp(email: email.trim(), token: token.trim());
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: 'Unable to verify code.');
      return false;
    }
  }

  Future<void> upsertProfile() async {
    try {
      await _repo.upsertProfile(displayName: state.pendingDisplayName);
    } catch (_) {
      // Best-effort; ignore if table not ready.
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthActionState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
