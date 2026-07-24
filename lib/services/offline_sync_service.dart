import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'local_database.dart';
import 'supabase_service.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isSyncing = false;

  Future<void> initialize() async {
    if (kIsWeb) return;

    await _syncWhenOnline();

    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncWhenOnline();
      }
    });
  }

  Future<void> _syncWhenOnline() async {
    if (_isSyncing) return;
    final status = await _connectivity.checkConnectivity();
    if (status == ConnectivityResult.none) return;

    _isSyncing = true;
    try {
      await _processPendingListings();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processPendingListings() async {
    final pendingRows = await LocalDatabase().getPendingListings();
    if (pendingRows.isEmpty) return;

    for (final row in pendingRows) {
      final id = row['id'] as int;
      final title = row['title'] as String;
      final description = row['description'] as String?;
      final category = row['category'] as String;
      final type = row['type'] as String;
      final locationLat = _toDouble(row['location_lat']);
      final locationLng = _toDouble(row['location_lng']);
      final imageBase64 = row['image_base64'] as String?;

      String? photoUrl;
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          final bytes = base64Decode(imageBase64);
          photoUrl = await SupabaseService.uploadPhotoBytes(
            bytes: bytes,
            fileName: 'pending_$id.jpg',
          );
        } catch (e) {
          // If photo upload fails, continue without the image.
        }
      }

      try {
        await SupabaseService.createListing(
          title: title,
          description: description ?? '',
          category: category,
          type: type,
          photoUrl: photoUrl,
          latitude: locationLat,
          longitude: locationLng,
        );

        await LocalDatabase().deletePendingListing(id);
      } catch (e) {
        // Stop processing remaining rows to preserve order.
        return;
      }
    }

    await _refreshBrowseCache();
  }

  Future<void> _refreshBrowseCache() async {
    try {
      final response = await SupabaseService.client
          .from('listings')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final listings = List<Map<String, dynamic>>.from(response);
      final processedListings = <Map<String, dynamic>>[];

      for (final listing in listings) {
        final ownerId = listing['owner_id'] as String?;
        if (ownerId != null) {
          try {
            final ownerResponse = await SupabaseService.client
                .from('users')
                .select('*')
                .eq('id', ownerId)
                .maybeSingle();
            listing['owner_name'] = ownerResponse?['name'] ?? 'Unknown Owner';
          } catch (_) {
            listing['owner_name'] = 'Unknown Owner';
          }
        } else {
          listing['owner_name'] = 'Unknown Owner';
        }

        processedListings.add(listing);
      }

      await LocalDatabase().cacheListings(processedListings);
    } catch (_) {
      // Refresh cache only when possible; ignore failures.
    }
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
