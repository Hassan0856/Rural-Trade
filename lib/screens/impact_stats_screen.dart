import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/impact_stats_provider.dart';

class ImpactStatsScreen extends ConsumerStatefulWidget {
  const ImpactStatsScreen({super.key});

  @override
  ConsumerState<ImpactStatsScreen> createState() => _ImpactStatsScreenState();
}

class _ImpactStatsScreenState extends ConsumerState<ImpactStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(impactStatsProvider.notifier).fetchImpactStats();
    });
  }

  Future<void> _shareStats() async {
    final statsState = ref.read(impactStatsProvider);
    
    final shareText = '''
🌾 Village Exchange Impact

📊 Total Listings Shared: ${statsState.totalListings}
✅ Requests Fulfilled: ${statsState.totalRequestsFulfilled}
⏱️ Idle Hours Saved: ${statsState.idleHoursSaved}

Together, we're building stronger village communities!
    '''.trim();

    try {
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(impactStatsProvider);

    ref.listen<ImpactStatsState>(impactStatsProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(impactStatsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Impact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareStats,
            tooltip: 'Share Stats',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Our Collective Impact',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'See how Village Exchange is helping communities share resources and save time.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (statsState.status == ImpactStatsStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (statsState.status == ImpactStatsStatus.error)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load stats',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(impactStatsProvider.notifier).fetchImpactStats();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              _ImpactCard(
                totalListings: statsState.totalListings,
                totalRequestsFulfilled: statsState.totalRequestsFulfilled,
                idleHoursSaved: statsState.idleHoursSaved,
                onShare: _shareStats,
              ),
            
            const SizedBox(height: 32),
            _InfoCard(),
          ],
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final int totalListings;
  final int totalRequestsFulfilled;
  final int idleHoursSaved;
  final VoidCallback onShare;

  const _ImpactCard({
    required this.totalListings,
    required this.totalRequestsFulfilled,
    required this.idleHoursSaved,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.green.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'Village Exchange',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Community Impact Report',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              
              _StatRow(
                icon: Icons.list_alt,
                label: 'Listings Shared',
                value: totalListings.toString(),
              ),
              const SizedBox(height: 24),
              
              _StatRow(
                icon: Icons.check_circle,
                label: 'Requests Fulfilled',
                value: totalRequestsFulfilled.toString(),
              ),
              const SizedBox(height: 24),
              
              _StatRow(
                icon: Icons.access_time,
                label: 'Idle Hours Saved',
                value: '$idleHoursSaved hrs',
              ),
              
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share),
                label: const Text('Share Impact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'How We Calculate Impact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Total Listings Shared: Count of all active listings in the community\n'
              '• Requests Fulfilled: Number of successfully completed exchanges\n'
              '• Idle Hours Saved: Estimated as 4 hours per completed exchange',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
