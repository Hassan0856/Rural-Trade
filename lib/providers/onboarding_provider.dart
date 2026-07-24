import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingState extends ChangeNotifier {
  bool _languageSelected = false;
  bool _onboardingSeen = false;
  bool _profileComplete = false;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;

  bool get languageSelected => _languageSelected;
  bool get onboardingSeen => _onboardingSeen;
  bool get isSignedIn => Supabase.instance.client.auth.currentSession != null;
  bool get profileComplete => _profileComplete;
  bool get initialized => _initialized;

  OnboardingState();

  void init() {
    if (_initialized) return;
    _initialized = true;
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      // When user signs in, check if profile is complete
      if (data.event == AuthChangeEvent.signedIn) {
        await _checkProfileComplete();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _profileComplete = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkProfileComplete() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _profileComplete = false;
      return;
    }

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select('name, village')
          .eq('id', user.id)
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
        _profileComplete = false;
      }
    } catch (e) {
      _profileComplete = false;
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
