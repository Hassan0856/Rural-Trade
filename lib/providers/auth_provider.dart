import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  needsProfile,
}

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();
  
  AuthNotifier() : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (_authService.isSignedIn) {
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, phoneNumber: phoneNumber);
    
    try {
      await _authService.sendOtp(phoneNumber);
      state = state.copyWith(status: AuthStatus.otpSent);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final needsProfile = await _authService.verifyOtpAndSignIn(
        rawPhone: state.phoneNumber!,
        code: otp,
      );
      
      if (needsProfile) {
        state = state.copyWith(status: AuthStatus.needsProfile);
      } else {
        state = state.copyWith(status: AuthStatus.authenticated);
      }
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
