// lib/services/auth_service.dart
//
// DEMO AUTH — phone number + fixed demo OTP, nothing else.
//
// This version adds retry-with-backoff around the profile-completion
// check, plus a persisted local flag as a fast path for returning users.
//
// Why: Supabase's ongoing migration to asymmetric (ES256) JWT signing
// causes intermittent "invalid JWT" verification failures — the same
// issue diagnosed earlier for the ensure-demo-user edge function. When
// that hit the profile-completion check, an earlier version of this file
// defaulted to "treat as complete" on any error, to avoid bouncing
// RETURNING users back to a blank setup screen on a transient glitch.
// That default was wrong for BRAND NEW users: their very first check can
// hit the same glitch and get silently shipped to Home with placeholder
// data still in the users row.
//
// Fix: never guess on an unresolved error, in either direction.
//   - Returning users: a local SharedPreferences flag, set only once a
//     real completeProfile() call has succeeded, short-circuits the
//     check entirely — no network call, so no exposure to this flakiness
//     at all after the first successful setup.
//   - New users: retry the Supabase check up to 3 times with backoff
//     before giving up. If it still fails, return null — the caller must
//     show a "couldn't verify your account, tap to retry" state, never
//     silently choose Home or profile setup.
//
// SECURITY NOTE: demo-grade only. The password is derivable from the
// phone number. Fine for a hackathon demo, not for production. To ship
// for real: delete this file's email/password logic and use
// supabase.auth.signInWithOtp(phone: ...) / verifyOTP(type: OtpType.sms)
// with a real SMS provider configured. Nothing else in the app changes.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String demoOtp = '123456';
  static const String _emailDomain = 'village-exchange.app';
  static const String _profileCompletedKey = 'profile_completed';

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

  Future<void> _backoff(int attempt) =>
      Future.delayed(Duration(seconds: 1 << attempt)); // 1s, 2s

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
        throw AuthException(msg ?? 'Could not verify this number.');
      }
    } on FunctionException catch (e) {
      throw AuthException(
        'Could not reach the login service (${e.details ?? e.reasonPhrase}). '
        'Check that the ensure-demo-user function is deployed.',
      );
    }

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

  /// Creates the profile row if missing, retrying on transient errors
  /// (see file header). Returns true if profile setup is still needed.
  /// Throws AuthException only after retries are exhausted — this always
  /// surfaces as a visible error on the OTP screen, never a silent skip.
  Future<bool> _ensureProfileRow({
    required String uid,
    required String phone,
  }) async {
    Map<String, dynamic>? existing;
    Object? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        existing = await _client
            .from('users')
            .select('id, name, village')
            .eq('id', uid)
            .maybeSingle();
        lastError = null;
        break;
      } catch (e) {
        lastError = e;
        if (attempt < 2) await _backoff(attempt);
      }
    }
    if (lastError != null) {
      throw AuthException('Could not verify your account. Please try again.');
    }

    if (existing != null) {
      final name = existing['name'] as String?;
      final village = existing['village'] as String?;
      return name == null ||
          village == null ||
          name == 'New villager' ||
          village == 'Unknown';
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        // id MUST equal auth.uid(), or every RLS policy on users,
        // listings and requests will silently deny this user.
        await _client.from('users').insert({
          'id': uid,
          'name': 'New villager',
          'phone': phone,
          'village': 'Unknown',
        });
        return true;
      } catch (e) {
        if (attempt == 2) {
          throw AuthException(
              'Could not set up your profile. Please try again.');
        }
        await _backoff(attempt);
      }
    }
    return true; // unreachable
  }

  /// Called by the profile setup screen on save.
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
      ...?(lat != null ? {'location_lat': lat} : null),
      ...?(lng != null ? {'location_lng': lng} : null),
    }).eq('id', uid);

    // Fast path for every future check on this device — see
    // checkProfileComplete() below.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileCompletedKey, true);
  }

  /// The single source of truth for routing after sign-in. Call this
  /// instead of querying "users" directly from router/state code.
  ///
  /// Returns:
  ///   true  -> profile is complete, go to Home
  ///   false -> profile is incomplete, go to profile setup
  ///   null  -> could not be determined after retries. Do NOT guess —
  ///            show a "couldn't verify your account, tap to retry" state
  ///            and call this again when the user retries.
  Future<bool?> checkProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_profileCompletedKey) == true) {
      return true; // no network call — immune to the JWT flakiness
    }

    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final row = await _client
            .from('users')
            .select('name, village')
            .eq('id', uid)
            .maybeSingle();

        if (row == null) return false;

        final complete = row['name'] != null &&
            row['village'] != null &&
            row['name'] != 'New villager' &&
            row['village'] != 'Unknown';

        if (complete) {
          await prefs.setBool(_profileCompletedKey, true);
        }
        return complete;
      } catch (_) {
        if (attempt < 2) await _backoff(attempt);
      }
    }
    return null; // exhausted retries — caller must not guess
  }

  Future<void> signOut() => _client.auth.signOut();

  bool get isSignedIn => _client.auth.currentSession != null;
  String? get currentUserId => _client.auth.currentUser?.id;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
