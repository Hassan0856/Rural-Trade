import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/listing_enums.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String listingId;

  const ResourceDetailScreen({super.key, required this.listingId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  bool _isRequesting = false;
  bool _hasRequested = false;
  Map<String, dynamic>? _ownerData;
  Map<String, dynamic>? _ownerRating;
  Map<String, dynamic>? _listing;
  bool _isLoading = true;

  // Earthy color palette
  static const Color _earthBrown = Color(0xFF8B5A2B);
  static const Color _earthGreen = Color(0xFF556B2F);
  static const Color _earthBeige = Color(0xFFF5F5DC);
  static const Color _earthTan = Color(0xFFD2B48C);
  static const Color _earthDarkGreen = Color(0xFF2F4F4F);

  @override
  void initState() {
    super.initState();
    _fetchListing();
  }

  Future<void> _fetchListing() async {
    try {
      final response = await SupabaseService.client
          .from('listings')
          .select('*')
          .eq('id', widget.listingId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _listing = response;
          _isLoading = false;
        });
        _checkIfAlreadyRequested();
        _fetchOwnerData();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchOwnerData() async {
    if (_listing == null) return;
    
    try {
      final ownerId = _listing!['owner_id'];
      if (ownerId == null) return;

      // Fetch owner data from users table
      final ownerResponse = await SupabaseService.client
          .from('users')
          .select('*')
          .eq('id', ownerId)
          .maybeSingle();

      if (ownerResponse != null && mounted) {
        setState(() {
          _ownerData = ownerResponse;
        });
      }

      // Fetch owner reviews
      final reviewsResponse = await SupabaseService.client
          .from('reviews')
          .select('rating')
          .eq('reviewee_id', ownerId);

      if (reviewsResponse.isNotEmpty && mounted) {
        final reviews = List<Map<String, dynamic>>.from(reviewsResponse);
        final totalRating = reviews.fold<double>(
          0, 
          (sum, review) => sum + ((review['rating'] as num?)?.toDouble() ?? 0.0)
        );
        final averageRating = totalRating / reviews.length;

        setState(() {
          _ownerRating = {
            'averageRating': averageRating,
            'reviewCount': reviews.length,
          };
        });
      }
    } catch (e) {
      // Error fetching owner data
    }
  }

  String _getVerificationBadge() {
    if (_ownerData == null) return 'New trader';
    
    final badgeLevel = _ownerData!['badge_level'] as String? ?? 'new';
    final trustScore = (_ownerData!['trust_score'] as num?)?.toDouble() ?? 0.0;
    
    if (badgeLevel == 'flagged' || trustScore < 0) {
      return 'Flagged';
    } else if (badgeLevel == 'verified' || trustScore >= 80) {
      return 'Verified';
    } else {
      return 'New trader';
    }
  }

  Color _getVerificationBadgeColor(String badge) {
    switch (badge) {
      case 'Verified':
        return Colors.green;
      case 'Flagged':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _checkIfAlreadyRequested() async {
    if (_listing == null) return;
    
    try {
      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await SupabaseService.client
          .from('requests')
          .select()
          .eq('requester_id', currentUserId)
          .eq('listing_id', _listing!['id'])
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _hasRequested = true;
        });
      }
    } catch (e) {
      // Error checking request status
    }
  }

  Future<void> _requestResource() async {
    if (_listing == null) return;
    
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    if (currentUserId == null) {
      _showErrorToast('You must be logged in to request a resource');
      return;
    }

    if (currentUserId == _listing!['owner_id']) {
      _showErrorToast('You cannot request your own listing');
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    try {
      await SupabaseService.client.from('requests').insert({
        'requester_id': currentUserId,
        'owner_id': _listing!['owner_id'],
        'listing_id': _listing!['id'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isRequesting = false;
          _hasRequested = true;
        });
        _showSuccessToast('Request sent successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
        _showErrorToast('Failed to send request: $e');
      }
    }
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: _earthGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'rent':
        return Icons.agriculture;
      case 'lend':
        return Icons.handyman;
      case 'sell':
        return Icons.sell;
      case 'exchange':
        return Icons.swap_horiz;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _earthBeige,
        appBar: AppBar(
          backgroundColor: _earthGreen,
          foregroundColor: Colors.white,
          title: const Text('Resource Details'),
          elevation: 2,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_listing == null) {
      return Scaffold(
        backgroundColor: _earthBeige,
        appBar: AppBar(
          backgroundColor: _earthGreen,
          foregroundColor: Colors.white,
          title: const Text('Resource Details'),
          elevation: 2,
        ),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final listing = _listing!;
    final photoUrl = listing['photo_url'];
    final typeKey = listing['type'] as String? ?? 'rent';
    final typeLabel = "${typeKey[0].toUpperCase()}${typeKey.substring(1)}";
    final typeDisplay = ListingEnums.exchangeTypes[typeKey] ?? typeLabel;
    final distance = listing['distance'] ?? 'Unknown';
    final isAvailable = listing['status'] == 'active';

    return Scaffold(
      backgroundColor: _earthBeige,
      appBar: AppBar(
        backgroundColor: _earthGreen,
        foregroundColor: Colors.white,
        title: const Text('Resource Details'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full Photo
            if (photoUrl != null && photoUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 250,
                color: _earthTan.withValues(alpha: 0.3),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(typeKey);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: _earthGreen,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                color: _earthTan.withValues(alpha: 0.3),
                child: _buildPlaceholder(typeKey),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _earthDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Type Badge
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(typeKey),
                        size: 18,
                        color: _earthBrown,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        typeDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: _earthBrown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? _earthGreen.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAvailable ? _earthGreen : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? _earthGreen : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: _earthGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _earthGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _earthDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing['description'] ?? 'No description provided.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _earthDarkGreen.withValues(alpha:8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Owner Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _earthTan),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _earthGreen,
                              radius: 24,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Owner',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    listing['owner_name'] ?? _ownerData?['name'] ?? 'Unknown Owner',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _earthDarkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Verification Badge and Rating
                        Row(
                          children: [
                            // Verification Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getVerificationBadgeColor(_getVerificationBadge()).withValues(alpha:15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getVerificationBadgeColor(_getVerificationBadge()),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getVerificationBadge() == 'Verified' 
                                        ? Icons.verified 
                                        : _getVerificationBadge() == 'Flagged'
                                            ? Icons.warning
                                            : Icons.person_outline,
                                    size: 14,
                                    color: _getVerificationBadgeColor(_getVerificationBadge()),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getVerificationBadge(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getVerificationBadgeColor(_getVerificationBadge()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Rating
                            if (_ownerRating != null && _ownerRating!['reviewCount'] > 0)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${_ownerRating!['averageRating'].toStringAsFixed(1)} ★',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ', ${_ownerRating!['reviewCount']} trades',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _earthBrown.withValues(alpha:7),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Request Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _hasRequested || !isAvailable
                          ? null
                          : _isRequesting
                              ? null
                              : _requestResource,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _earthGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isRequesting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : _hasRequested
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check),
                                    SizedBox(width: 8),
                                    Text('Request Sent'),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send),
                                    SizedBox(width: 8),
                                    Text('Request This'),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info text
                  if (!_hasRequested && isAvailable)
                    Text(
                      'By requesting, you\'ll be connected with the owner to arrange the exchange.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _earthBrown.withValues(alpha:7),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String type) {
    IconData icon;
    switch (type) {
      case 'rent':
        icon = Icons.agriculture;
        break;
      case 'lend':
        icon = Icons.handyman;
        break;
      case 'sell':
        icon = Icons.sell;
        break;
      case 'exchange':
        icon = Icons.swap_horiz;
        break;
      default:
        icon = Icons.inventory_2;
    }

    final typeLabel = "${type[0].toUpperCase()}${type.substring(1)}";
    final typeDisplay = ListingEnums.exchangeTypes[type] ?? typeLabel;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: _earthBrown.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            typeDisplay,
            style: TextStyle(
              fontSize: 16,
              color: _earthBrown.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
