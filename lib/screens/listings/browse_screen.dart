import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../services/local_database.dart';
import '../../services/supabase_service.dart';
import '../../models/listing_enums.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/offline_banner.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
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
  bool _isShowingSavedListings = false;
  List<Map<String, dynamic>> _listings = [];
  Position? _userPosition;
  String? _errorMessage;

  String get _currentLanguage => languageProvider.language ?? 'en';

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
    if (ownerData == null) return AppStrings.t('badge_new_trader', 'en');
    
    final badgeLevel = ownerData['badge_level'] as String? ?? 'new';
    final trustScore = (ownerData['trust_score'] as num?)?.toDouble() ?? 0.0;
    
    if (badgeLevel == 'flagged' || trustScore < 0) {
      return AppStrings.t('badge_flagged', 'en');
    } else if (badgeLevel == 'verified' || trustScore >= 80) {
      return AppStrings.t('badge_verified', 'en');
    } else {
      return AppStrings.t('badge_new_trader', 'en');
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

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    final canUseLocalCache = !kIsWeb;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isShowingSavedListings = false;
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

      final response = await SupabaseService.client
          .from('listings')
          .select('*, owner:users!owner_id(name, badge_level, trust_score)')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final listings = List<Map<String, dynamic>>.from(response);

      for (var listing in listings) {
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

        final rawOwner = listing['owner'];
        Map<String, dynamic>? ownerData;
        if (rawOwner is List && rawOwner.isNotEmpty) {
          ownerData = Map<String, dynamic>.from(rawOwner.first as Map);
        } else if (rawOwner is Map<String, dynamic>) {
          ownerData = rawOwner;
        }

        listing['ownerData'] = ownerData;
        listing['owner_name'] = ownerData?['name'] ?? 'Unknown Owner';
        listing['verificationBadge'] = _getVerificationBadge(ownerData);
        listing['badgeColor'] = _getVerificationBadgeColor(
          listing['verificationBadge'] as String,
        );
        listing['ownerRating'] = 0.0;
        listing['ownerReviewCount'] = 0;
      }

      final cacheableListings = listings
          .map((listing) => {
                'id': listing['id'],
                'title': listing['title'],
                'description': listing['description'],
                'category': listing['category'],
                'type': listing['type'],
                'location_lat': listing['location_lat'],
                'location_lng': listing['location_lng'],
                'location_name': listing['location_name'],
                'photo_url': listing['photo_url'],
                'owner_id': listing['owner_id'],
                'owner_name': listing['owner_name'] ?? 'Unknown Owner',
                'owner_phone': listing['owner_phone'],
                'status': listing['status'],
                'created_at': listing['created_at'],
              })
          .toList();

      if (canUseLocalCache) {
        await LocalDatabase().cacheListings(cacheableListings);
      }

      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    } catch (e) {
      if (canUseLocalCache) {
        final cachedListings = await LocalDatabase().getCachedListings();
        if (cachedListings.isNotEmpty) {
          _applyCachedListings(cachedListings);
          return;
        }
      }

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyCachedListings(List<Map<String, dynamic>> cachedListings) {
    for (var listing in cachedListings) {
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
    }

    setState(() {
      _listings = cachedListings;
      _isShowingSavedListings = true;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = languageProvider.language ?? 'en';
    return Scaffold(
      backgroundColor: _earthBeige,
      appBar: AppBar(
        backgroundColor: _earthGreen,
        foregroundColor: Colors.white,
        title: Text(AppStrings.t('browse_title', currentLanguage)),
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
          const OfflineBanner(),
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: _earthBeige,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.t('browse_search_hint', currentLanguage),
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

          if (_isShowingSavedListings)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.storage, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing saved listings while offline',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
                      ? AppStrings.t('category_all', currentLanguage)
                      : AppStrings.t('category_$category', currentLanguage);
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
    final currentLanguage = _currentLanguage;
    return Container(
      color: _earthBeige,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.t('browse_loading_message', currentLanguage),
              style: TextStyle(
                color: _earthDarkGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 16,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 60,
                              height: 14,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 80,
                              height: 14,
                              color: Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final currentLanguage = _currentLanguage;
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
              AppStrings.t('browse_error_title', currentLanguage),
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
              label: Text(AppStrings.t('browse_try_again_button', currentLanguage)),
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
    final currentLanguage = _currentLanguage;
    final message = _selectedCategory == 'All' && _searchController.text.isEmpty
        ? AppStrings.t('browse_empty_all_message', currentLanguage)
        : AppStrings.t('browse_empty_filter_message', currentLanguage);

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
              AppStrings.t('browse_empty_title', currentLanguage),
              style: TextStyle(
                color: _earthDarkGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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
    final currentLanguage = languageProvider.language ?? 'en';
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
          return _buildListingCard(listing, currentLanguage);
        },
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing, String currentLanguage) {
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
                                child: listing['distance'] != null &&
                                      listing['distance'].toString().toLowerCase() != 'unknown'
                                  ? Text(
                                      listing['distance'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _earthGreen,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : const SizedBox.shrink(),
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
                        isAvailable 
                            ? AppStrings.t('status_available', currentLanguage)
                            : AppStrings.t('status_requested', currentLanguage),
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
