import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

class TradeRequest {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingCategory;
  final String listingType;
  final String? listingPhotoUrl;
  final String requesterId;
  final String requesterName;
  final String ownerId;
  final String ownerName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSent; // true if user is requester, false if user is owner

  TradeRequest({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingCategory,
    required this.listingType,
    this.listingPhotoUrl,
    required this.requesterId,
    required this.requesterName,
    required this.ownerId,
    required this.ownerName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.isSent,
  });

  factory TradeRequest.fromJson(Map<String, dynamic> json, String currentUserId) {
    final listing = json['listings'] as Map<String, dynamic>;
    final requester = json['users'] as Map<String, dynamic>;
    final owner = json['owner'] as Map<String, dynamic>;
    
    return TradeRequest(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      listingTitle: listing['title'] as String,
      listingCategory: listing['category'] as String,
      listingType: listing['type'] as String,
      listingPhotoUrl: listing['photo_url'] as String?,
      requesterId: json['requester_id'] as String,
      requesterName: requester['name'] as String,
      ownerId: listing['owner_id'] as String,
      ownerName: owner['name'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isSent: json['requester_id'] == currentUserId,
    );
  }
}

enum TradesStatus {
  initial,
  loading,
  loaded,
  error,
}

class TradesState {
  final TradesStatus status;
  final String? errorMessage;
  final List<TradeRequest> trades;

  TradesState({
    this.status = TradesStatus.initial,
    this.errorMessage,
    this.trades = const [],
  });

  TradesState copyWith({
    TradesStatus? status,
    String? errorMessage,
    List<TradeRequest>? trades,
  }) {
    return TradesState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      trades: trades ?? this.trades,
    );
  }
}

class TradesNotifier extends StateNotifier<TradesState> {
  TradesNotifier() : super(TradesState());

  Future<void> fetchUserTrades() async {
    state = state.copyWith(status: TradesStatus.loading, errorMessage: null);

    try {
      final userId = SupabaseService.client.auth.currentUser!.id;

      // Fetch requests where user is requester
      final sentRequests = await SupabaseService.client
          .from('requests')
          .select('*, listings(*, users(name)), owner:users(name)')
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      // Fetch requests where user is listing owner
      final receivedRequests = await SupabaseService.client
          .from('requests')
          .select('*, listings(*, users(name)), owner:users(name)')
          .eq('listings.owner_id', userId)
          .neq('requester_id', userId)
          .order('created_at', ascending: false);

      final allTrades = [...sentRequests, ...receivedRequests]
          .map((json) => TradeRequest.fromJson(json, userId))
          .toList();

      // Sort by updated_at descending
      allTrades.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      state = state.copyWith(
        status: TradesStatus.loaded,
        trades: allTrades,
      );
    } catch (e) {
      state = state.copyWith(
        status: TradesStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> submitReview({
    required String requestId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    try {
      final reviewerId = SupabaseService.client.auth.currentUser!.id;

      await SupabaseService.client.from('reviews').insert({
        'request_id': requestId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'rating': rating,
        'comment': comment,
      });

      // Refresh trades
      await fetchUserTrades();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> submitComplaint({
    required String requestId,
    required String category,
    required String description,
  }) async {
    try {
      final complainantId = SupabaseService.client.auth.currentUser!.id;

      // Fetch request to get both parties
      final request = await SupabaseService.client
          .from('requests')
          .select('requester_id, listings(owner_id)')
          .eq('id', requestId)
          .single();

      final requesterId = request['requester_id'] as String;
      final ownerId = request['listings']['owner_id'] as String;

      // Determine respondent (the other party)
      final respondentId = complainantId == requesterId ? ownerId : requesterId;

      await SupabaseService.client.from('complaints').insert({
        'request_id': requestId,
        'complainant_id': complainantId,
        'respondent_id': respondentId,
        'category': category,
        'description': description,
      });

      // Refresh trades
      await fetchUserTrades();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final tradesProvider = StateNotifierProvider<TradesNotifier, TradesState>((ref) {
  return TradesNotifier();
});
