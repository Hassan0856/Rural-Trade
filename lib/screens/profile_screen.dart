import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../providers/user_listings_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userListingsProvider.notifier).fetchUserListings();
    });
  }

  Future<void> _showEditDialog(UserListing listing) async {
    final titleController = TextEditingController(text: listing.title);
    final descriptionController = TextEditingController(text: listing.description ?? '');
    final categoryController = TextEditingController(text: listing.category);
    final typeController = TextEditingController(text: listing.type);

    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Listing'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Type (rent/lend/sell/exchange)'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final dialogContext = context;
                await ref.read(userListingsProvider.notifier).updateListing(
                      listingId: listing.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      category: categoryController.text,
                      type: typeController.text,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(UserListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(userListingsProvider.notifier).deleteListing(listing.id);
    }
  }

  Future<void> _confirmMarkUnavailable(UserListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Unavailable'),
        content: Text('Mark "${listing.title}" as unavailable?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Unavailable'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(userListingsProvider.notifier).markAsUnavailable(listing.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userListingsState = ref.watch(userListingsProvider);
    final userId = SupabaseService.client.auth.currentUser?.id;

    ref.listen<UserListingsState>(userListingsProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(userListingsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/phone');
            },
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, dynamic>?>(
              future: _fetchUserProfile(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final userProfile = snapshot.data;
                if (userProfile == null) {
                  return const Center(child: Text('Profile not found'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.green.shade100,
                                child: Text(
                                  userProfile['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userProfile['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            userProfile['village'] ?? 'Unknown village',
                                            style: const TextStyle(color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats Row
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(
                                icon: Icons.list,
                                label: 'Listings Shared',
                                value: userListingsState.totalListings.toString(),
                              ),
                              const VerticalDivider(width: 32),
                              _StatItem(
                                icon: Icons.check_circle,
                                label: 'Requests Fulfilled',
                                value: userListingsState.fulfilledRequests.toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // My Listings Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Listings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  context.go('/profile/my-trades');
                                },
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: const Text('My Trades'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  context.go('/add-listing');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add New'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (userListingsState.status == UserListingsStatus.loading)
                        const Center(child: CircularProgressIndicator())
                      else if (userListingsState.listings.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No listings yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userListingsState.listings.length,
                          itemBuilder: (context, index) {
                            final listing = userListingsState.listings[index];
                            return _ListingCard(
                              listing: listing,
                              onEdit: () => _showEditDialog(listing),
                              onDelete: () => _confirmDelete(listing),
                              onMarkUnavailable: () => _confirmMarkUnavailable(listing),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<Map<String, dynamic>?> _fetchUserProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.green),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  final UserListing listing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkUnavailable;

  const _ListingCard({
    required this.listing,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final isInactive = listing.status == 'inactive';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (listing.photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      listing.photoUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.agriculture, color: Colors.green.shade700),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusChip(status: listing.status),
                          const SizedBox(width: 8),
                          Text(
                            listing.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isInactive)
                  TextButton.icon(
                    onPressed: onMarkUnavailable,
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Unavailable'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        label = 'Active';
        break;
      case 'inactive':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        label = 'Unavailable';
        break;
      case 'completed':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        label = 'Completed';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
