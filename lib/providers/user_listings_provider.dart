import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

class UserListing {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String type;
  final String? photoUrl;
  final String status;
  final double? locationLat;
  final double? locationLng;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserListing({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.type,
    this.photoUrl,
    required this.status,
    this.locationLat,
    this.locationLng,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserListing.fromJson(Map<String, dynamic> json) {
    return UserListing(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      type: json['type'] as String,
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

enum UserListingsStatus {
  initial,
  loading,
  loaded,
  error,
}

class UserListingsState {
  final UserListingsStatus status;
  final String? errorMessage;
  final List<UserListing> listings;
  final int totalListings;
  final int fulfilledRequests;

  UserListingsState({
    this.status = UserListingsStatus.initial,
    this.errorMessage,
    this.listings = const [],
    this.totalListings = 0,
    this.fulfilledRequests = 0,
  });

  UserListingsState copyWith({
    UserListingsStatus? status,
    String? errorMessage,
    List<UserListing>? listings,
    int? totalListings,
    int? fulfilledRequests,
  }) {
    return UserListingsState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      listings: listings ?? this.listings,
      totalListings: totalListings ?? this.totalListings,
      fulfilledRequests: fulfilledRequests ?? this.fulfilledRequests,
    );
  }
}

class UserListingsNotifier extends StateNotifier<UserListingsState> {
  UserListingsNotifier() : super(UserListingsState());

  Future<void> fetchUserListings() async {
    state = state.copyWith(status: UserListingsStatus.loading, errorMessage: null);

    try {
      final userId = SupabaseService.client.auth.currentUser!.id;

      final response = await SupabaseService.client
          .from('listings')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      final listings = (response as List)
          .map((json) => UserListing.fromJson(json as Map<String, dynamic>))
          .toList();

      // Fetch fulfilled requests count
      final requestsResponse = await SupabaseService.client
          .from('requests')
          .select('listings!inner(owner_id)')
          .eq('listings.owner_id', userId)
          .eq('status', 'completed');

      final fulfilledRequests = (requestsResponse as List).length;

      state = state.copyWith(
        status: UserListingsStatus.loaded,
        listings: listings,
        totalListings: listings.length,
        fulfilledRequests: fulfilledRequests,
      );
    } catch (e) {
      state = state.copyWith(
        status: UserListingsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateListing({
    required String listingId,
    String? title,
    String? description,
    String? category,
    String? type,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (type != null) updateData['type'] = type;

      await SupabaseService.client
          .from('listings')
          .update(updateData)
          .eq('id', listingId);

      // Refresh listings
      await fetchUserListings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> markAsUnavailable(String listingId) async {
    try {
      await SupabaseService.client
          .from('listings')
          .update({'status': 'inactive'})
          .eq('id', listingId);

      // Refresh listings
      await fetchUserListings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteListing(String listingId) async {
    try {
      await SupabaseService.client
          .from('listings')
          .delete()
          .eq('id', listingId);

      // Refresh listings
      await fetchUserListings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final userListingsProvider =
    StateNotifierProvider<UserListingsNotifier, UserListingsState>((ref) {
  return UserListingsNotifier();
});
