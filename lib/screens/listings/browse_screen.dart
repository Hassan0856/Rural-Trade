import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../services/supabase_service.dart';
import '../../models/listing_enums.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', ...ListingEnums.categories.keys];

  // Earthy color palette
  static const Color _earthBrown = Color(0xFF8B5A2B);
  static const Color _earthGreen = Color(0xFF556B2F);
  static const Color _earthBeige = Color(0xFFF5F5DC);
  static const Color _earthTan = Color(0xFFD2B48C);
  static const Color _earthDarkGreen = Color(0xFF2F4F4F);

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _listings = [];
  Position? _userPosition;
  String? _errorMessage;

  List<Map<String, dynamic>> get _filteredListings {
    var filtered = _listings;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((listing) => listing['category'] == _selectedCategory)
          .toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered
          .where((listing) =>
              listing['title'].toString().toLowerCase().contains(searchLower))
          .toList();
    }

    // Sort by distance if user position is available
    if (_userPosition != null) {
      filtered.sort((a, b) {
        final distanceA = a['distanceInKm'] ?? double.infinity;
        final distanceB = b['distanceInKm'] ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }

    return filtered;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1.0) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }

  String _getVerificationBadge(Map<String, dynamic>? ownerData) {
    if (ownerData == null) return 'New trader';
    
    final badgeLevel = ownerData['badge_level'] as String? ?? 'new';
    final trustScore = (ownerData['trust_score'] as num?)?.toDouble() ?? 0.0;
    
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

  Future<Map<String, dynamic>> _getOwnerRating(String ownerId) async {
    try {
      final response = await SupabaseService.client
          .from('reviews')
          .select('rating')
          .eq('reviewee_id', ownerId);
      
      if (response.isNotEmpty) {
        final reviews = List<Map<String, dynamic>>.from(response);
        final totalRating = reviews.fold<double>(
          0, 
          (sum, review) => sum + ((review['rating'] as num?)?.toDouble() ?? 0.0)
        );
        final averageRating = totalRating / reviews.length;
        
        return {
          'averageRating': averageRating,
          'reviewCount': reviews.length,
        };
      }
    } catch (e) {
      // Error fetching reviews - silently return default values
    }
    
    return {
      'averageRating': 0.0,
      'reviewCount': 0,
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user location
      final status = await Permission.location.request();
      if (status.isGranted) {
        try {
          _userPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        } catch (e) {
          // Continue without location if it fails
        }
      }

      // Fetch all active listings from Supabase (no user filter)
      final response = await SupabaseService.client
          .from('listings')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final listings = List<Map<String, dynamic>>.from(response);

      // Process each listing
      for (var listing in listings) {
        // Calculate distances
        if (_userPosition != null &&
            listing['location_lat'] != null &&
            listing['location_lng'] != null) {
            final distance = _calculateDistance(
              _userPosition!.latitude,
              _userPosition!.longitude,
              listing['location_lat'] as double,
              listing['location_lng'] as double,
            );
            listing['distanceInKm'] = distance;
            listing['distance'] = _formatDistance(distance);
          } else {
            listing['distanceInKm'] = double.infinity;
            listing['distance'] = 'Unknown';
          }

          // Fetch owner data separately for each listing
          final ownerId = listing['owner_id'] as String?;
          if (ownerId != null) {
            try {
              final ownerResponse = await SupabaseService.client
                  .from('users')
                  .select('*')
                  .eq('id', ownerId)
                  .maybeSingle();
              
              final ownerData = ownerResponse;
              listing['ownerData'] = ownerData;
              listing['owner_name'] = ownerData?['name'] ?? 'Unknown Owner';
              
              // Get verification badge
              final badge = _getVerificationBadge(ownerData);
              listing['verificationBadge'] = badge;
              listing['badgeColor'] = _getVerificationBadgeColor(badge);

              // Fetch owner rating
              final ratingData = await _getOwnerRating(ownerId);
              listing['ownerRating'] = ratingData['averageRating'] as double;
              listing['ownerReviewCount'] = (ratingData['reviewCount'] as num?)?.round() ?? 0;
            } catch (e) {
              listing['ownerData'] = null;
              listing['owner_name'] = 'Unknown Owner';
              listing['ownerRating'] = 0.0;
              listing['ownerReviewCount'] = 0;
            }
          } else {
            listing['ownerData'] = null;
            listing['owner_name'] = 'Unknown Owner';
            listing['ownerRating'] = 0.0;
            listing['ownerReviewCount'] = 0;
          }
        }

        setState(() {
          _listings = listings;
          _isLoading = false;
        });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _earthBeige,
      appBar: AppBar(
        backgroundColor: _earthGreen,
        foregroundColor: Colors.white,
        title: const Text('Browse Resources'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchListings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: _earthBeige,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: const Icon(Icons.search, color: _earthBrown),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _earthTan),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _earthTan),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _earthBrown, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _earthBeige,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  final displayLabel = category == 'All' 
                      ? 'All' 
                      : ListingEnums.categories[category] ?? category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(displayLabel),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: _earthGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : _earthBrown,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(color: _earthTan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredListings.isEmpty
                        ? _buildEmptyState()
                        : _buildListingsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: _earthGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading resources...',
            style: TextStyle(
              color: _earthBrown,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load resources',
              style: TextStyle(
                color: _earthDarkGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: TextStyle(
                color: _earthBrown,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchListings,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _earthGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: _earthBrown.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No resources found',
              style: TextStyle(
                color: _earthDarkGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory == 'All' && _searchController.text.isEmpty
                  ? 'There are no listings nearby at the moment'
                  : 'Try adjusting your filters or search terms',
              style: TextStyle(
                color: _earthBrown,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsGrid() {
    return Container(
      color: _earthBeige,
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredListings.length,
        itemBuilder: (context, index) {
          final listing = _filteredListings[index];
          return _buildListingCard(listing);
        },
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final isAvailable = listing['status'] == 'active';
    final photoUrl = listing['photo_url'];
    final typeKey = listing['type'] as String? ?? 'rent';
    final typeLabel = "${typeKey[0].toUpperCase()}${typeKey.substring(1)}";
    final typeDisplay = ListingEnums.exchangeTypes[typeKey] ?? typeLabel;
    
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/browse/resource-detail/${listing['id']}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resource Photo (placeholder or actual image)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: _earthTan.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
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
                    : _buildPlaceholder(typeKey),
              ),
            ),

            // Card Content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _earthDarkGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getTypeIcon(typeKey),
                                size: 14,
                                color: _earthBrown,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  typeDisplay,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _earthBrown,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: _earthGreen,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  listing['distance'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _earthGreen,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (listing['ownerReviewCount'] != null &&
                              listing['ownerReviewCount'] > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    '${listing['ownerRating']?.toStringAsFixed(1) ?? '0.0'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    ' (${listing['ownerReviewCount']})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _earthBrown.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (listing['badgeColor'] as Color?)
                                ?.withValues(alpha: 0.15) ??
                            Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: listing['badgeColor'] as Color? ??
                              Colors.orange,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        listing['verificationBadge'] ?? 'New trader',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: listing['badgeColor'] as Color? ??
                              Colors.orange,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
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
                        'Available',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? _earthGreen : Colors.orange,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
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
            size: 48,
            color: _earthBrown.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            typeDisplay,
            style: TextStyle(
              fontSize: 12,
              color: _earthBrown.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
}
