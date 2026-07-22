import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

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
  AuthNotifier() : super(AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, phoneNumber: phoneNumber);
    
    try {
      await SupabaseService.auth.signInWithOtp(
        phone: phoneNumber,
      );
      state = state.copyWith(status: AuthStatus.otpSent);
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
      final response = await SupabaseService.auth.verifyOTP(
        phone: state.phoneNumber!,
        token: otp,
        type: OtpType.sms,
      );

      if (response.session != null) {
        final userId = response.user!.id;
        final hasProfile = await _checkUserProfile(userId);
        
        if (hasProfile) {
          state = state.copyWith(status: AuthStatus.authenticated);
        } else {
          state = state.copyWith(status: AuthStatus.needsProfile);
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> _checkUserProfile(String userId) async {
    try {
      await SupabaseService.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> createProfile({
    required String name,
    required String village,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final userId = SupabaseService.auth.currentUser!.id;
      
      await SupabaseService.client.from('users').insert({
        'id': userId,
        'name': name,
        'phone': state.phoneNumber,
        'village': village,
        'location_lat': latitude,
        'location_lng': longitude,
      });

      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.needsProfile,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
