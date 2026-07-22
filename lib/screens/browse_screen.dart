import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/supabase_service.dart';
import 'resource_detail_screen.dart';
import 'dart:math';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Tractor', 'Water Pump', 'Generator', 'Tools', 'Produce', 'Other'];
  
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _filteredListings = [];
  bool _isLoading = true;
  String? _errorMessage;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user location
      await _getCurrentLocation();
      
      // Fetch listings from Supabase
      final listings = await SupabaseService.fetchListings();
      
      // Fetch owner data for each listing
      final listingsWithOwnerData = await Future.wait(listings.map((listing) async {
        final ownerId = listing['owner_id'].toString();
        final ownerData = await SupabaseService.fetchUserData(ownerId);
        final ownerReviews = await SupabaseService.fetchUserReviews(ownerId);
        return {
          ...listing,
          'owner_data': ownerData,
          'owner_reviews': ownerReviews,
        };
      }));
      
      // Calculate distances and sort
      final listingsWithDistance = listingsWithOwnerData.map((listing) {
        final distance = _calculateDistance(
          _userPosition?.latitude ?? 0,
          _userPosition?.longitude ?? 0,
          listing['location_lat'] ?? 0,
          listing['location_lng'] ?? 0,
        );
        return {...listing, 'distance': distance};
      }).toList();
      
      // Sort by distance
      listingsWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      setState(() {
        _listings = listingsWithDistance;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userPosition = position;
      });
    } catch (e) {
      // Continue without location if permission denied or error
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // in kilometers
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_listings);

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((listing) => listing['category'] == _selectedCategory).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((listing) =>
              listing['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredListings = filtered;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Resources'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => _applyFilters(),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _applyFilters();
                      });
                    },
                    selectedColor: Colors.green.shade200,
                    checkmarkColor: Colors.green.shade800,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.green.shade800 : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredListings.length} result${_filteredListings.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Grid of listing cards
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading listings',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredListings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _listings.isEmpty ? 'No listings available' : 'No resources found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_listings.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Be the first to add a resource!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredListings.length,
      itemBuilder: (context, index) {
        final listing = _filteredListings[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResourceDetailScreen(listing: listing),
              ),
            );
          },
          child: _ListingCard(listing: listing),
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;

  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final isAvailable = listing['status'] == 'active';
    final hasPhoto = listing['photo_url'] != null && listing['photo_url'].toString().isNotEmpty;
    final distance = listing['distance'] as double? ?? 0.0;
    final ownerData = listing['owner_data'] as Map<String, dynamic>?;
    final ownerReviews = listing['owner_reviews'] as Map<String, dynamic>?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo placeholder or actual photo
          Expanded(
            flex: 3,
            child: hasPhoto
                ? Container(
                    color: Colors.green.shade100,
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(listing['category']),
                        size: 48,
                        color: Colors.green.shade700,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Card content
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    listing['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing['type'] ?? 'Other',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.brown.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Owner verification badge
                  if (ownerData != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: SupabaseService.getVerificationBadgeColor(
                          SupabaseService.getVerificationBadge(
                            ownerData['trust_score'] as int?,
                            ownerData['badge_level'] as String?,
                          ),
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: SupabaseService.getVerificationBadgeColor(
                            SupabaseService.getVerificationBadge(
                              ownerData['trust_score'] as int?,
                              ownerData['badge_level'] as String?,
                            ),
                          ),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getVerificationIcon(
                              SupabaseService.getVerificationBadge(
                                ownerData['trust_score'] as int?,
                                ownerData['badge_level'] as String?,
                              ),
                            ),
                            size: 10,
                            color: SupabaseService.getVerificationBadgeColor(
                              SupabaseService.getVerificationBadge(
                                ownerData['trust_score'] as int?,
                                ownerData['badge_level'] as String?,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            SupabaseService.getVerificationBadge(
                              ownerData['trust_score'] as int?,
                              ownerData['badge_level'] as String?,
                            ),
                            style: TextStyle(
                              fontSize: 9,
                              color: SupabaseService.getVerificationBadgeColor(
                                SupabaseService.getVerificationBadge(
                                  ownerData['trust_score'] as int?,
                                  ownerData['badge_level'] as String?,
                                ),
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Distance and rating
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      if (ownerReviews != null && ownerReviews['totalReviews'] > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${ownerReviews['averageRating'].toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Requested',
                      style: TextStyle(
                        fontSize: 10,
                        color: isAvailable ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
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

  IconData _getVerificationIcon(String badge) {
    switch (badge.toLowerCase()) {
      case 'verified':
        return Icons.verified;
      case 'flagged':
        return Icons.warning;
      case 'new trader':
      default:
        return Icons.person_outline;
    }
  }

  IconData _getCategoryIcon(String category) {
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
