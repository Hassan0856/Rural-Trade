import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/language_service.dart';
import '../services/auth_service.dart';

class OnboardingState extends ChangeNotifier {
  bool _languageSelected = false;
  bool _onboardingSeen = false;
  bool? _profileComplete;
  bool _authReady = false;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  String _currentLanguage = 'en';
  bool _profileCheckFailed = false;

  bool get languageSelected => _languageSelected;
  bool get onboardingSeen => _onboardingSeen;
  bool get isSignedIn => Supabase.instance.client.auth.currentSession != null;
  bool? get profileComplete => _profileComplete;
  bool get authReady => _authReady;
  bool get initialized => _initialized;
  String get currentLanguage => _currentLanguage;
  bool get profileCheckFailed => _profileCheckFailed;

  OnboardingState();

  /// Must be called once after Supabase.initialize() completes.
  Future<void> initAsync() async {
    if (_initialized) return;
    _initialized = true;
    
    // Load saved language preference
    final languageService = LanguageService();
    final savedLanguage = await languageService.getLanguage();
    if (savedLanguage != null) {
      _currentLanguage = savedLanguage;
    }
    
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
    final authService = AuthService();
    final result = await authService.checkProfileComplete();
    
    if (result == null) {
      // Could not determine after retries - show retry state
      _profileComplete = null;
      _profileCheckFailed = true;
    } else {
      _profileComplete = result;
      _profileCheckFailed = false;
    }
    notifyListeners();
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

  void setCurrentLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }

  /// Public method to retry profile check after a failure
  Future<void> retryProfileCheck() async {
    await _checkProfileComplete();
  }
}

final onboardingProvider = OnboardingState();
