import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/language_provider.dart';
import '../services/weather_service.dart';
import '../services/ai_service.dart';
import '../services/language_service.dart';
import '../l10n/app_strings.dart';
import '../widgets/offline_banner.dart';
import '../widgets/language_picker_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _weatherAlert;
  bool _showWeatherBanner = true;
  final WeatherService _weatherService = WeatherService();
  final AiService _aiService = AiService();

  @override
  void initState() {
    super.initState();
    languageProvider.addListener(_handleLanguageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).fetchUnreadCount();
      _checkWeatherAndListings();
    });
  }

  @override
  void dispose() {
    languageProvider.removeListener(_handleLanguageChanged);
    super.dispose();
  }

  void _handleLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkWeatherAndListings() async {
    try {
      // Get user's location from users table
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final userData = await Supabase.instance.client
          .from('users')
          .select('location_lat, location_lng')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return;

      final lat = userData['location_lat'] as double?;
      final lng = userData['location_lng'] as double?;

      if (lat == null || lng == null) return;

      // Check if no rain is forecast
      final hasRain = await _weatherService.hasRainInForecast(
        latitude: lat,
        longitude: lng,
      );

      if (hasRain) return; // Rain is forecast, no alert needed

      // Count nearby produce listings
      final listingsResponse = await Supabase.instance.client
          .from('listings')
          .select('id')
          .eq('category', 'produce')
          .eq('status', 'active')
          .limit(10);

      final produceCount = listingsResponse.length;

      if (produceCount == 0) return;

      // Generate AI alert
      final alert = await _aiService.demandForecastAlert(
        produceListingCount: produceCount,
        languageCode: languageProvider.language,
      );

      if (alert != null && mounted) {
        setState(() {
          _weatherAlert = alert;
        });
      }
    } catch (e) {
      // Silently fail on weather check errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(notificationsProvider).unreadCount;
    final currentLanguage = languageProvider.language ?? 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('nav_home', currentLanguage)),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Change language',
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (sheetContext) {
                  return LanguagePickerSheet(
                    onLanguageSelected: (languageCode) async {
                      final languageService = LanguageService();
                      await languageService.setLanguage(languageCode);
                      languageProvider.setLanguage(languageCode);
                      if (!mounted) return;
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              child: const Icon(Icons.notifications),
            ),
            onPressed: () async {
              await context.push('/home/notifications');
              if (mounted) {
                ref.read(notificationsProvider.notifier).fetchUnreadCount();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/welcome');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          // Weather Alert Banner
          if (_weatherAlert != null && _showWeatherBanner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _weatherAlert!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _showWeatherBanner = false;
                      });
                    },
                    color: Colors.orange.shade800,
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.t('home_welcome_title', currentLanguage),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.t('home_logged_in_subtitle', currentLanguage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/add-listing');
                    },
                    icon: const Icon(Icons.add),
                    label: Text(AppStrings.t('home_add_listing_button', currentLanguage)),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go('/profile/my-trades');
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(AppStrings.t('home_my_trades_button', currentLanguage)),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.go('/profile/impact-stats');
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: Text(AppStrings.t('home_view_impact_button', currentLanguage)),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
