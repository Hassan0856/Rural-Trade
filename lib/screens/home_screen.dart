import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(notificationsProvider).unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Village Exchange'),
        actions: [
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Village Exchange!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Text(
              'You are now logged in',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/add-listing');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Listing'),
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
              label: const Text('My Trades'),
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
              label: const Text('View Impact Stats'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
