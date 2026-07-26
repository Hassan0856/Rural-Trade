import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';

class AiService {
  Future<String?> _generate(String prompt, {String? languageCode}) async {
    try {
      // Prepend language instruction if non-English (stronger adherence at start)
      final languageInstruction = languageCode != null
          ? AppStrings.languageInstruction(languageCode)
          : null;
      final fullPrompt = languageInstruction != null
          ? '$languageInstruction\n\n$prompt'
          : prompt;

      // DIAGNOSIS: Log the exact prompt being sent
      developer.log('[AI_SERVICE] languageCode: $languageCode');
      developer.log('[AI_SERVICE] languageInstruction: $languageInstruction');
      developer.log('[AI_SERVICE] fullPrompt: $fullPrompt');

      Future<String?> invokeAi() async {
        final res = await Supabase.instance.client.functions.invoke(
          'gemini-generate',
          body: {'prompt': fullPrompt},
        );

        if (res.status == 429) {
          developer.log('[AI_SERVICE] gemini-generate quota exhausted: status=${res.status}, data=${res.data}');
          return '__NO_RETRY__';
        }

        if (res.status != 200) {
          developer.log('[AI_SERVICE] gemini-generate failed: status=${res.status}, data=${res.data}');
          return null;
        }

        final text = (res.data is Map) ? res.data['text'] as String? : null;
        if (text == null || text.isEmpty) {
          developer.log('[AI_SERVICE] gemini-generate returned empty response: data=${res.data}');
          return null;
        }
        return text.trim();
      }

      for (var attempt = 1; attempt <= 3; attempt++) {
        final result = await invokeAi();
        if (result == '__NO_RETRY__') return null;
        if (result != null) return result;

        if (attempt < 3) {
          final delay = attempt == 1 ? 1 : 2;
          await Future.delayed(Duration(seconds: delay));
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// One sentence on why [listing] might match nearby open requests.
  Future<String?> matchExplanation({
    required Map<String, dynamic> listing,
    required List<Map<String, dynamic>> nearbyRequests,
    String? languageCode,
  }) async {
    if (nearbyRequests.isEmpty) return null;

    final title = listing['title'] ?? 'Untitled';
    final description = listing['description'] ?? '';
    final category = listing['category'] ?? '';

    final requestSummary = nearbyRequests
        .take(5)
        .map((r) {
          final listingData = r['listings'] as Map<String, dynamic>?;
          final reqTitle = listingData?['title'] ?? 'Unknown';
          final reqCategory = listingData?['category'] ?? '';
          return '- $reqTitle ($reqCategory)';
        })
        .join('\n');

    final prompt =
        'You help villagers share farm equipment and produce on Rural Trader. '
        'In one short, friendly sentence (max 25 words), explain why this listing '
        'might be a good match for nearby open requests. No bullet points.\n\n'
        'Listing: "$title" (category: $category)\n'
        'Description: $description\n\n'
        'Nearby open requests:\n$requestSummary';

    return _generate(prompt, languageCode: languageCode);
  }

  /// One sentence trust summary for a trader.
  Future<String?> trustSummary({
    required double ratingAvg,
    required int ratingCount,
    required int complaintCount,
    String? languageCode,
  }) async {
    final prompt =
        'Write one short, friendly sentence (max 20 words) summarizing this '
        'village trader\'s reputation. Examples: "Reliable trader, 12 exchanges, '
        'no complaints" or "New to the platform, no history yet". '
        'Use the data literally.\n\n'
        'Average rating: ${ratingCount > 0 ? ratingAvg.toStringAsFixed(1) : 'none'}\n'
        'Review count: $ratingCount\n'
        'Complaint count: $complaintCount';

    return _generate(prompt, languageCode: languageCode);
  }

  /// Friendly alert when dry weather meets nearby produce listings.
  Future<String?> demandForecastAlert({
    required int produceListingCount,
    String? languageCode,
  }) async {
    final prompt =
        'Write one short, friendly sentence (max 25 words) alerting a villager '
        'that no rain is forecast for 5 days and there are $produceListingCount '
        'nearby produce listings — suggest checking water pump availability. '
        'Keep it warm and practical, no bullet points.';

    return _generate(prompt, languageCode: languageCode);
  }
}
