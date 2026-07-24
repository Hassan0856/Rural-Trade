// lib/services/auth_service.dart
//
// DEMO AUTH — phone number + fixed demo OTP, nothing else.
//
// Why this exists: real SMS OTP needs a paid provider, and Indian numbers
// additionally need TRAI DLT registration. Neither is feasible in a 48h
// hackathon.
//
// Why this version (not the earlier ones):
//   - Anonymous sign-in gives a NEW auth.uid() every session, which
//     collided with the UNIQUE constraint on users.phone.
//   - Client-side signUp() respects the project's "Confirm email" setting,
//     and any account created while that setting was on is permanently
//     stuck unconfirmed — no client code can fix that after the fact.
// This version calls the "ensure-demo-user" Edge Function, which creates
// the account server-side with email_confirm forced true. That bypasses
// the confirmation requirement at creation time, so it cannot fail this
// way again regardless of the dashboard setting.
//
// Identity is still deterministic: the same phone number always maps to
// the same email/password, therefore the same auth.uid(), therefore the
// same row in the users table. Every RLS policy in 01_schema.sql works
// unchanged, because auth.uid() is a real, confirmed session.
//
// SECURITY NOTE: demo-grade only. The password is derivable from the
// phone number. Fine for a hackathon demo, not for production. To ship
// for real: delete this file's email/password logic and use
// supabase.auth.signInWithOtp(phone: ...) / verifyOTP(type: OtpType.sms)
// with a real SMS provider configured. Nothing else in the app changes.

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String demoOtp = '123456';
  static const String _emailDomain = 'village-exchange.app';

  static String normalisePhone(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) digits = '91$digits';
    return '+$digits';
  }

  static String _digits(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  static String _syntheticEmail(String phone) =>
      '${_digits(phone)}@$_emailDomain';

  static String _syntheticPassword(String phone) =>
      'vx_${_digits(phone)}_demo';

  /// Step 1 — validates the number. No network call needed; the demo code
  /// is fixed and shown on screen in debug builds.
  Future<void> sendOtp(String rawPhone) async {
    final phone = normalisePhone(rawPhone);
    if (_digits(phone).length < 12) {
      throw AuthException('Please enter a valid 10-digit mobile number.');
    }
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Step 2 — verifies the code, ensures a confirmed account exists via
  /// the edge function, signs in, and returns true if profile setup is
  /// still needed.
  Future<bool> verifyOtpAndSignIn({
    required String rawPhone,
    required String code,
  }) async {
    if (code.trim() != demoOtp) {
      throw AuthException('Incorrect code. Please try again.');
    }

    final phone = normalisePhone(rawPhone);
    final email = _syntheticEmail(phone);
    final password = _syntheticPassword(phone);

    final current = _client.auth.currentUser;
    if (current != null && current.email != email) {
      await _client.auth.signOut();
    }

    try {
      final res = await _client.functions.invoke(
        'ensure-demo-user',
        body: {'phone': phone, 'otp': code.trim()},
      );
      if (res.status != 200) {
        final msg = (res.data is Map) ? res.data['error'] : null;
        throw AuthException(msg ?? 'Could not verify this number ($res.status).');
      }
    } on FunctionException catch (e) {
      throw AuthException(
        'Could not reach the login service (${e.details ?? e.reasonPhrase}). '
        'Check that the ensure-demo-user function is deployed.',
      );
    }

    // The account is now guaranteed to exist and be confirmed.
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw AuthException('Could not start a session. Please try again.');
    }

    return _ensureProfileRow(uid: user.id, phone: phone);
  }

  Future<bool> _ensureProfileRow({
    required String uid,
    required String phone,
  }) async {
    final existing = await _client
        .from('users')
        .select('id, name, village')
        .eq('id', uid)
        .maybeSingle();

    if (existing != null) {
      final name = existing['name'] as String?;
      final village = existing['village'] as String?;
      return name == null ||
          village == null ||
          name == 'New villager' ||
          village == 'Unknown';
    }

    await _client.from('users').insert({
      'id': uid, // MUST equal auth.uid(), or every RLS policy denies this user
      'name': 'New villager',
      'phone': phone,
      'village': 'Unknown',
    });
    return true;
  }

  Future<void> completeProfile({
    required String name,
    required String village,
    double? lat,
    double? lng,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('No active session.');

    await _client.from('users').update({
      'name': name.trim(),
      'village': village.trim(),
      // Omit entirely when off — never write 0.0, a real Gulf-of-Guinea
      // coordinate that would wreck the distance sort.
      if (lat != null) 'location_lat': lat,
      if (lng != null) 'location_lng': lng,
    }).eq('id', uid);
  }

  Future<void> signOut() => _client.auth.signOut();

  bool get isSignedIn => _client.auth.currentSession != null;
  String? get currentUserId => _client.auth.currentUser?.id;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}