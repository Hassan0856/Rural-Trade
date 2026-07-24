// lib/services/language_service.dart
//
// Stores the villager's chosen language once, on first launch, before
// onboarding. Also used to preselect the voice-input language dropdown
// on the Add Listing screen, so the choice isn't asked twice.

import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const _key = 'app_language';

  /// 'en', 'hi', or 'te' — matches the speech_to_text language dropdown
  /// already used on the Add Listing voice input.
  static const supported = {
    'en': 'English',
    'hi': 'हिन्दी',
    'te': 'తెలుగు',
  };

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}