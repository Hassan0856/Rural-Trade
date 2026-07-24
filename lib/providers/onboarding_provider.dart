import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingState extends ChangeNotifier {
  bool _languageSelected = false;
  bool _onboardingSeen = false;
  bool _profileComplete = false;
  bool _authReady = false;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;

  bool get languageSelected => _languageSelected;
  bool get onboardingSeen => _onboardingSeen;
  bool get isSignedIn => Supabase.instance.client.auth.currentSession != null;
  bool get profileComplete => _profileComplete;
  bool get authReady => _authReady;
  bool get initialized => _initialized;

  OnboardingState();

  /// Must be called once after Supabase.initialize() completes.
  Future<void> initAsync() async {
    if (_initialized) return;
    _initialized = true;
    _initAuthListener();
    await _restoreSessionAndCheckProfile();
    _authReady = true;
    notifyListeners();
  }

  void _initAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        if (data.event == AuthChangeEvent.signedIn) {
          await _checkProfileComplete();
          notifyListeners();
        } else if (data.event == AuthChangeEvent.signedOut) {
          _profileComplete = false;
          notifyListeners();
        }
      },
    );
  }

  /// Wait until Supabase session is restored, then check profile if signed in.
  Future<void> _restoreSessionAndCheckProfile() async {
    await _waitForSessionRestored();

    if (Supabase.instance.client.auth.currentSession != null) {
      await _checkProfileComplete();
    }
  }

  /// Blocks until auth session restoration completes or times out.
  Future<void> _waitForSessionRestored() async {
    if (Supabase.instance.client.auth.currentSession != null) return;

    // Poll — session is usually available immediately after initialize(),
    // but may take a moment to hydrate from local storage.
    const maxAttempts = 25;
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (Supabase.instance.client.auth.currentSession != null) return;
    }

    if (kDebugMode) {
      print('[Onboarding] No session restored after waiting — treating as signed out');
    }
  }

  Future<void> _checkProfileComplete() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _profileComplete = false;
      return;
    }

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select('name, village')
          .eq('id', session.user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (userData != null) {
        final name = userData['name'] as String?;
        final village = userData['village'] as String?;
        _profileComplete = name != null &&
            village != null &&
            name != 'New villager' &&
            village != 'Unknown';
      } else {
        // Row not found but session exists — fail toward Home, not re-onboarding.
        if (kDebugMode) {
          print('[Onboarding] No users row for ${session.user.id} — treating as complete');
        }
        _profileComplete = true;
      }
    } catch (e) {
      // Query failed/timed out but session exists — fail toward Home.
      if (kDebugMode) {
        print('[Onboarding] Profile check error: $e — treating as complete');
      }
      if (Supabase.instance.client.auth.currentSession != null) {
        _profileComplete = true;
      } else {
        _profileComplete = false;
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void setLanguageSelected(bool value) {
    _languageSelected = value;
    notifyListeners();
  }

  void setOnboardingSeen(bool value) {
    _onboardingSeen = value;
    notifyListeners();
  }

  void setProfileComplete(bool value) {
    _profileComplete = value;
    notifyListeners();
  }
}

final onboardingProvider = OnboardingState();
