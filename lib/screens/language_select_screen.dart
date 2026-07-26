import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';
import '../providers/language_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/language_picker_sheet.dart';

class LanguageSelectScreen extends StatelessWidget {
  final String? returnTo;

  const LanguageSelectScreen({super.key, this.returnTo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: LanguagePickerSheet(
            title: 'Select your language',
            onLanguageSelected: (languageCode) async {
              final languageService = LanguageService();
              await languageService.setLanguage(languageCode);
              languageProvider.setLanguage(languageCode);
              onboardingProvider.setLanguageSelected(true);
              onboardingProvider.setCurrentLanguage(languageCode);
              if (context.mounted) {
                if (returnTo != null && returnTo!.isNotEmpty) {
                  context.go(returnTo!);
                } else {
                  context.go('/onboarding');
                }
              }
            },
          ),
        ),
      ),
    );
  }
}
