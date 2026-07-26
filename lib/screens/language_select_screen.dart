import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';
import '../providers/language_provider.dart';
import '../providers/onboarding_provider.dart';

class LanguageSelectScreen extends StatelessWidget {
  final String? returnTo;

  const LanguageSelectScreen({super.key, this.returnTo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.language,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 32),
              const Text(
                'Select your language',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ...LanguageService.supported.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final languageService = LanguageService();
                      await languageService.setLanguage(entry.key);
                      languageProvider.setLanguage(entry.key);
                      onboardingProvider.setLanguageSelected(true);
                      onboardingProvider.setCurrentLanguage(entry.key);
                      if (context.mounted) {
                        if (returnTo != null && returnTo!.isNotEmpty) {
                          context.go(returnTo!);
                        } else {
                          context.go('/onboarding');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: Text(entry.value),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
