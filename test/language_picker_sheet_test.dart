import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:village_exchange/widgets/language_picker_sheet.dart';

void main() {
  testWidgets('renders the language picker options', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguagePickerSheet(
            onLanguageSelected: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Select your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('తెలుగు'), findsOneWidget);
  });
}
