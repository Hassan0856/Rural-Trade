import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguagePickerSheet extends StatelessWidget {
  final Future<void> Function(String languageCode)? onLanguageSelected;
  final String title;

  const LanguagePickerSheet({
    super.key,
    this.onLanguageSelected,
    this.title = 'Select your language',
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.language,
              size: 56,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...LanguageService.supported.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (onLanguageSelected != null) {
                      await onLanguageSelected!(entry.key);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: Text(entry.value),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
