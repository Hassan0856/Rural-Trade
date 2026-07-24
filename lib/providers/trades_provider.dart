import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final bool isSent;
  final bool hasUserReviewed;
  final bool hasUserComplained;

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
    this.hasUserReviewed = false,
    this.hasUserComplained = false,
  });

  factory TradeRequest.fromJson(
    Map<String, dynamic> json,
    String currentUserId, {
    Set<String>? reviewedRequestIds,
    Set<String>? complainedRequestIds,
  }) {
    final listing = json['listings'] as Map<String, dynamic>;
    final requester = json['requester'] as Map<String, dynamic>? ??
        json['users'] as Map<String, dynamic>? ??
        {'name': 'Unknown'};
    final owner = listing['owner'] as Map<String, dynamic>? ??
        json['owner'] as Map<String, dynamic>? ??
        {'name': 'Unknown', 'id': listing['owner_id']};

    final requestId = json['id'] as String;

    return TradeRequest(
      id: requestId,
      listingId: json['listing_id'] as String,
      listingTitle: listing['title'] as String? ?? 'Untitled',
      listingCategory: listing['category'] as String? ?? '',
      listingType: listing['type'] as String? ?? '',
      listingPhotoUrl: listing['photo_url'] as String?,
      requesterId: json['requester_id'] as String,
      requesterName: requester['name'] as String? ?? 'Unknown',
      ownerId: listing['owner_id'] as String,
      ownerName: owner['name'] as String? ?? 'Unknown',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isSent: json['requester_id'] == currentUserId,
      hasUserReviewed: reviewedRequestIds?.contains(requestId) ?? false,
      hasUserComplained: complainedRequestIds?.contains(requestId) ?? false,
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
  final List<TradeRequest> incomingPending;

  TradesState({
    this.status = TradesStatus.initial,
    this.errorMessage,
    this.trades = const [],
    this.incomingPending = const [],
  });

  TradesState copyWith({
    TradesStatus? status,
    String? errorMessage,
    List<TradeRequest>? trades,
    List<TradeRequest>? incomingPending,
  }) {
    return TradesState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      trades: trades ?? this.trades,
      incomingPending: incomingPending ?? this.incomingPending,
    );
  }
}

class TradesNotifier extends StateNotifier<TradesState> {
  TradesNotifier() : super(TradesState());

  static const _requestSelect =
      '*, listings(*, owner:users!owner_id(name, id)), requester:users!requester_id(name, id)';

  Future<Set<String>> _fetchUserReviewedRequestIds(String userId) async {
    try {
      final rows = await SupabaseService.client
          .from('reviews')
          .select('request_id')
          .eq('reviewer_id', userId);
      return rows.map((r) => r['request_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> _fetchUserComplainedRequestIds(String userId) async {
    try {
      final rows = await SupabaseService.client
          .from('complaints')
          .select('request_id')
          .eq('complainant_id', userId);
      return rows.map((r) => r['request_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> fetchUserTrades() async {
    state = state.copyWith(status: TradesStatus.loading, errorMessage: null);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final reviewedIds = await _fetchUserReviewedRequestIds(userId);
      final complainedIds = await _fetchUserComplainedRequestIds(userId);

      final sentRequests = await SupabaseService.client
          .from('requests')
          .select(_requestSelect)
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      // Fetch requests on listings owned by this user
      final ownedListings = await SupabaseService.client
          .from('listings')
          .select('id')
          .eq('owner_id', userId);

      final listingIds =
          ownedListings.map((l) => l['id'] as String).toList();

      List<dynamic> receivedRequests = [];
      if (listingIds.isNotEmpty) {
        receivedRequests = await SupabaseService.client
            .from('requests')
            .select(_requestSelect)
            .inFilter('listing_id', listingIds)
            .neq('requester_id', userId)
            .order('created_at', ascending: false);
      }

      final allTrades = [...sentRequests, ...receivedRequests]
          .map((json) => TradeRequest.fromJson(
                json,
                userId,
                reviewedRequestIds: reviewedIds,
                complainedRequestIds: complainedIds,
              ))
          .toList();

      allTrades.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final incomingPending = allTrades
          .where((t) => !t.isSent && t.status == 'pending')
          .toList();

      state = state.copyWith(
        status: TradesStatus.loaded,
        trades: allTrades,
        incomingPending: incomingPending,
      );
    } on PostgrestException catch (e) {
      if (kDebugMode) print('[Trades] fetch error: ${e.message}');
      state = state.copyWith(
        status: TradesStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: TradesStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fetchIncomingRequests() async {
    await fetchUserTrades();
  }

  Future<String?> updateRequestStatus(String requestId, String status) async {
    try {
      await SupabaseService.client
          .from('requests')
          .update({'status': status})
          .eq('id', requestId);

      await fetchUserTrades();
      return null;
    } on PostgrestException catch (e) {
      if (kDebugMode) print('[Trades] update status error: ${e.message}');
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> acceptRequest(String requestId) =>
      updateRequestStatus(requestId, 'accepted');

  Future<String?> rejectRequest(String requestId) =>
      updateRequestStatus(requestId, 'rejected');

  Future<String?> completeRequest(String requestId) =>
      updateRequestStatus(requestId, 'completed');

  Future<String?> submitReview({
    required String requestId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    try {
      final reviewerId = Supabase.instance.client.auth.currentUser!.id;

      await SupabaseService.client.from('reviews').insert({
        'request_id': requestId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'rating': rating,
        'comment': comment,
      });

      await fetchUserTrades();
      return null;
    } on PostgrestException catch (e) {
      if (kDebugMode) print('[Trades] review error: ${e.message}');
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> submitComplaint({
    required String requestId,
    required String category,
    required String description,
  }) async {
    try {
      final complainantId = Supabase.instance.client.auth.currentUser!.id;

      final request = await SupabaseService.client
          .from('requests')
          .select('requester_id, listings(owner_id)')
          .eq('id', requestId)
          .single();

      final requesterId = request['requester_id'] as String;
      final ownerId = (request['listings'] as Map<String, dynamic>)['owner_id']
          as String;

      final respondentId =
          complainantId == requesterId ? ownerId : requesterId;

      await SupabaseService.client.from('complaints').insert({
        'request_id': requestId,
        'complainant_id': complainantId,
        'respondent_id': respondentId,
        'category': category,
        'description': description,
      });

      await fetchUserTrades();
      return null;
    } on PostgrestException catch (e) {
      if (kDebugMode) print('[Trades] complaint error: ${e.message}');
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final tradesProvider = StateNotifierProvider<TradesNotifier, TradesState>((ref) {
  return TradesNotifier();
});
