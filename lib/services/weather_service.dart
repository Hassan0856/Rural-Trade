import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';

class WeatherService {
  String? get _apiKey {
    final key = dotenv.env['OPENWEATHER_API_KEY'];
    if (key == null || key.isEmpty || key.startsWith('YOUR_')) return null;
    return key;
  }

  Future<String?> demandForecastAlert({
    required int produceListingCount,
    String? languageCode,
  }) async {
    final prompt =
        'Write one short, friendly sentence (max 25 words) alerting a villager '
        'that no rain is forecast for 5 days and there are $produceListingCount '
        'nearby produce listings — suggest checking water pump availability. '
        'Keep it warm and practical, no bullet points.';

    final languageInstruction = languageCode != null
        ? AppStrings.languageInstruction(languageCode)
        : null;
    final fullPrompt = languageInstruction != null
        ? '$languageInstruction\n\n$prompt'
        : prompt;

    Future<String?> invokeAi() async {
      final res = await Supabase.instance.client.functions.invoke(
        'gemini-generate',
        body: {'prompt': fullPrompt},
      );

      if (res.status != 200) {
        developer.log('[WEATHER_SERVICE] gemini-generate failed: status=${res.status}, data=${res.data}');
        return null;
      }

      final text = (res.data is Map) ? res.data['text'] as String? : null;
      if (text == null || text.isEmpty) {
        developer.log('[WEATHER_SERVICE] gemini-generate returned empty response: data=${res.data}');
        return null;
      }
      return text.trim();
    }

    for (var attempt = 1; attempt <= 3; attempt++) {
      final result = await invokeAi();
      if (result != null) return result;

      if (attempt < 3) {
        final delay = attempt == 1 ? 1 : 2;
        await Future.delayed(Duration(seconds: delay));
      }
    }

    return null;
  }

  /// Returns true if any rain is forecast within the next 5 days.
  Future<bool> hasRainInForecast({
    required double latitude,
    required double longitude,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null) return true; // fail safe — suppress banner

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast'
        '?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        developer.log('[WEATHER_SERVICE] forecast request failed: status=${response.statusCode}, body=${response.body}');
        return true;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['list'] as List<dynamic>? ?? [];

      for (final entry in list) {
        final item = entry as Map<String, dynamic>;
        final weather = item['weather'] as List<dynamic>? ?? [];
        for (final w in weather) {
          final main = (w as Map<String, dynamic>)['main'] as String? ?? '';
          if (main.toLowerCase().contains('rain') ||
              main.toLowerCase().contains('drizzle') ||
              main.toLowerCase().contains('thunderstorm')) {
            return true;
          }
        }
        final pop = (item['pop'] as num?)?.toDouble() ?? 0.0;
        if (pop >= 0.5) return true;
      }

      return false;
    } catch (error, stackTrace) {
      developer.log('[WEATHER_SERVICE] forecast request exception: $error', error: error, stackTrace: stackTrace);
      return true; // fail safe — suppress banner
    }
  }
}
