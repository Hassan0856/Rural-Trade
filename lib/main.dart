import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/phone_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/listings/add_listing_screen.dart';
import 'screens/listings/listing_success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Village Exchange',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/phone': (context) => const PhoneScreen(),
        '/otp': (context) => const OtpScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const HomeScreen(),
        '/add-listing': (context) => const AddListingScreen(),
        '/listing-success': (context) => const ListingSuccessScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = SupabaseService.client.auth.currentSession;

    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userId = session.user.id;
        final hasProfile = await _checkUserProfile(userId);
        if (hasProfile) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/profile-setup');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const PhoneScreen();
  }

  Future<bool> _checkUserProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response != null;
    } catch (e) {
      return false;
    }
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Village Exchange'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.pushReplacementNamed(context, '/phone');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Village Exchange!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('You are now logged in'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/add-listing');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Listing'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
