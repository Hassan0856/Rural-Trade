import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ResourceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ResourceDetailScreen({super.key, required this.listing});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  bool _isRequesting = false;
  bool _hasRequested = false;
  Map<String, dynamic>? _ownerData;
  Map<String, dynamic>? _ownerReviews;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  Future<void> _loadOwnerData() async {
    final ownerId = widget.listing['owner_id'].toString();
    
    final ownerData = await SupabaseService.fetchUserData(ownerId);
    final ownerReviews = await SupabaseService.fetchUserReviews(ownerId);
    
    if (mounted) {
      setState(() {
        _ownerData = ownerData;
        _ownerReviews = ownerReviews;
      });
    }
  }

  Future<void> _handleRequest() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      await SupabaseService.createRequest(
        listingId: widget.listing['id'].toString(),
        ownerId: widget.listing['owner_id'].toString(),
      );

      setState(() {
        _isRequesting = false;
        _hasRequested = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRequesting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final hasPhoto = listing['photo_url'] != null && listing['photo_url'].toString().isNotEmpty;
    final isAvailable = listing['status'] == 'active';
    final distance = listing['distance'] as double? ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            SizedBox(
              width: double.infinity,
              height: 250,
              child: hasPhoto
                  ? Container(
                      color: Colors.green.shade100,
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(listing['category']),
                          size: 80,
                          color: Colors.green.shade700,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No photo available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 14,
                            color: isAvailable ? Colors.green.shade800 : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      listing['type'] ?? 'Other',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.brown.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing['description'] ?? 'No description provided',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Owner info
                  const Text(
                    'Owner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade200,
                        child: Icon(
                          Icons.person,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  listing['owner_name'] ?? 'Owner',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_ownerData != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SupabaseService.getVerificationBadgeColor(
                                        SupabaseService.getVerificationBadge(
                                          _ownerData!['trust_score'] as int?,
                                          _ownerData!['badge_level'] as String?,
                                        ),
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: SupabaseService.getVerificationBadgeColor(
                                          SupabaseService.getVerificationBadge(
                                            _ownerData!['trust_score'] as int?,
                                            _ownerData!['badge_level'] as String?,
                                          ),
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      SupabaseService.getVerificationBadge(
                                        _ownerData!['trust_score'] as int?,
                                        _ownerData!['badge_level'] as String?,
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: SupabaseService.getVerificationBadgeColor(
                                          SupabaseService.getVerificationBadge(
                                            _ownerData!['trust_score'] as int?,
                                            _ownerData!['badge_level'] as String?,
                                          ),
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_ownerReviews != null && _ownerReviews!['totalReviews'] > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_ownerReviews!['averageRating'].toStringAsFixed(1)} ★',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_ownerReviews!['totalReviews']} trade${_ownerReviews!['totalReviews'] == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Distance
                  const Text(
                    'Distance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 24,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Request Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasRequested || !isAvailable ? null : _handleRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : _hasRequested
                              ? const Text('Request Sent', style: TextStyle(fontSize: 16))
                              : const Text('Request This', style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  if (_hasRequested) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your request has been sent to the owner. They will contact you soon.',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Tractor':
        return Icons.agriculture;
      case 'Water Pump':
        return Icons.water_drop;
      case 'Generator':
        return Icons.power;
      case 'Tools':
        return Icons.handyman;
      case 'Produce':
        return Icons.eco;
      default:
        return Icons.category;
    }
  }
}
