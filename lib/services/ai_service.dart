import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const _model = 'gemini-2.0-flash';

  String? get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty || key.startsWith('YOUR_')) return null;
    return key;
  }

  Future<String?> _generate(String prompt) async {
    final apiKey = _apiKey;
    if (apiKey == null) return null;

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'maxOutputTokens': 120,
                'temperature': 0.6,
              },
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text == null) return null;
      return text.toString().trim();
    } catch (_) {
      return null;
    }
  }

  /// One sentence on why [listing] might match nearby open requests.
  Future<String?> matchExplanation({
    required Map<String, dynamic> listing,
    required List<Map<String, dynamic>> nearbyRequests,
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
        'You help villagers share farm equipment and produce on Village Exchange. '
        'In one short, friendly sentence (max 25 words), explain why this listing '
        'might be a good match for nearby open requests. No bullet points.\n\n'
        'Listing: "$title" (category: $category)\n'
        'Description: $description\n\n'
        'Nearby open requests:\n$requestSummary';

    return _generate(prompt);
  }

  /// One sentence trust summary for a trader.
  Future<String?> trustSummary({
    required double ratingAvg,
    required int ratingCount,
    required int complaintCount,
  }) async {
    final prompt =
        'Write one short, friendly sentence (max 20 words) summarizing this '
        'village trader\'s reputation. Examples: "Reliable trader, 12 exchanges, '
        'no complaints" or "New to the platform, no history yet". '
        'Use the data literally.\n\n'
        'Average rating: ${ratingCount > 0 ? ratingAvg.toStringAsFixed(1) : 'none'}\n'
        'Review count: $ratingCount\n'
        'Complaint count: $complaintCount';

    return _generate(prompt);
  }

  /// Friendly alert when dry weather meets nearby produce listings.
  Future<String?> demandForecastAlert({
    required int produceListingCount,
  }) async {
    final prompt =
        'Write one short, friendly sentence (max 25 words) alerting a villager '
        'that no rain is forecast for 5 days and there are $produceListingCount '
        'nearby produce listings — suggest checking water pump availability. '
        'Keep it warm and practical, no bullet points.';

    return _generate(prompt);
  }
}
