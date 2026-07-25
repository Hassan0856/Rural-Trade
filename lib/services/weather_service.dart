import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  String? get _apiKey {
    final key = dotenv.env['OPENWEATHER_API_KEY'];
    if (key == null || key.isEmpty || key.startsWith('YOUR_')) return null;
    return key;
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
