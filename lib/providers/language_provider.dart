import 'package:flutter/foundation.dart';

class LanguageNotifier extends ChangeNotifier {
  String? _language;

  String? get language => _language;

  void setLanguage(String code) {
    _language = code;
    notifyListeners();
  }

  void clearLanguage() {
    _language = null;
    notifyListeners();
  }
}

final languageProvider = LanguageNotifier();
