import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'services/supabase_service.dart';
import 'providers/language_provider.dart';
import 'providers/onboarding_provider.dart';
import 'app_theme.dart';
import 'l10n/app_strings.dart';
import 'screens/auth/phone_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/auth/profile_retry_screen.dart';
import 'screens/listings/add_listing_screen.dart';
import 'screens/listings/listing_success_screen.dart';
import 'screens/listings/browse_screen.dart';
import 'screens/listings/resource_detail_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'services/offline_sync_service.dart';
import 'screens/impact_stats_screen.dart';
import 'screens/my_trades_screen.dart';
import 'screens/language_select_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved language preference for UI (not used for routing)
  final prefs = await SharedPreferences.getInstance();
  final language = prefs.getString('app_language');
  if (language != null) {
    languageProvider.setLanguage(language);
    onboardingProvider.setCurrentLanguage(language);
  }
  
  // Wrap Supabase initialization in 5-second timeout
  try {
    await SupabaseService.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        // If timeout, sign out to clear bad token and continue
        SupabaseService.auth.signOut();
        throw Exception('Supabase initialization timed out');
      },
    );
  } catch (e) {
    // If initialization fails or times out, sign out and continue
    try {
      await SupabaseService.auth.signOut();
    } catch (_) {
      // Ignore signOut errors
    }
  }
  
  // Wait for session restore + profile check before routing
  await onboardingProvider.initAsync();

  // Start background offline sync for pending listings on supported platforms.
  if (!kIsWeb) {
    OfflineSyncService().initialize();
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/welcome',
      refreshListenable: onboardingProvider,
      redirect: (context, state) {
        final currentPath = state.uri.path;
        final authReady = onboardingProvider.authReady;
        final signedIn = onboardingProvider.isSignedIn;
        final profileComplete = onboardingProvider.profileComplete;
        final profileCheckFailed = onboardingProvider.profileCheckFailed;

        const unauthenticatedPaths = {
          '/welcome',
          '/language-select',
          '/onboarding',
          '/phone',
          '/otp',
        };

        if (kDebugMode) {
          print('[GoRouter Redirect] Path: $currentPath, authReady: $authReady, signedIn: $signedIn, profileComplete: $profileComplete, profileCheckFailed: $profileCheckFailed');
        }

        if (!authReady) {
          return null;
        }

        if (!signedIn) {
          if (unauthenticatedPaths.contains(currentPath)) {
            return null;
          }
          return '/welcome';
        }

        // Handle null profileComplete - show retry screen
        if (profileComplete == null) {
          if (currentPath != '/profile-retry') {
            return '/profile-retry';
          }
          return null;
        }

        if (!profileComplete) {
          if (currentPath != '/profile-setup') {
            return '/profile-setup';
          }
          return null;
        }

        if (unauthenticatedPaths.contains(currentPath) ||
            currentPath == '/profile-setup' ||
            currentPath == '/profile-retry') {
          return '/home';
        }

        return null;
      },
      routes: [
        // Auth flow routes (outside shell)
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/language-select',
          builder: (context, state) => LanguageSelectScreen(
            returnTo: state.uri.queryParameters['returnTo'],
          ),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/phone',
          builder: (context, state) => const PhoneScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OtpScreen(),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/profile-retry',
          builder: (context, state) => const ProfileRetryScreen(),
        ),
        
        // Bottom navigation shell (authenticated routes)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                  routes: [
                    GoRoute(
                      path: 'notifications',
                      builder: (context, state) =>
                          const NotificationsScreen(),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/browse',
                  builder: (context, state) => const BrowseScreen(),
                  routes: [
                    GoRoute(
                      path: 'resource-detail/:id',
                      builder: (context, state) {
                        final listingId = state.pathParameters['id'] ?? '';
                        return ResourceDetailScreen(listingId: listingId);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/add-listing',
                  builder: (context, state) => const AddListingScreen(),
                  routes: [
                    GoRoute(
                      path: 'success',
                      builder: (context, state) => const ListingSuccessScreen(),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'impact-stats',
                      builder: (context, state) => const ImpactStatsScreen(),
                    ),
                    GoRoute(
                      path: 'my-trades',
                      builder: (context, state) {
                        final requestId =
                            state.uri.queryParameters['requestId'];
                        return MyTradesScreen(highlightRequestId: requestId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Rural Trader',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = languageProvider.language ?? 'en';
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppStrings.t('nav_home', currentLanguage),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: AppStrings.t('nav_browse', currentLanguage),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle),
            label: AppStrings.t('nav_add_listing', currentLanguage),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppStrings.t('nav_profile', currentLanguage),
          ),
        ],
      ),
    );
  }
}
