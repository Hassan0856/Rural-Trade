import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

enum ImpactStatsStatus {
  initial,
  loading,
  loaded,
  error,
}

class ImpactStatsState {
  final ImpactStatsStatus status;
  final String? errorMessage;
  final int totalListings;
  final int totalRequestsFulfilled;
  final int idleHoursSaved;

  ImpactStatsState({
    this.status = ImpactStatsStatus.initial,
    this.errorMessage,
    this.totalListings = 0,
    this.totalRequestsFulfilled = 0,
    this.idleHoursSaved = 0,
  });

  ImpactStatsState copyWith({
    ImpactStatsStatus? status,
    String? errorMessage,
    int? totalListings,
    int? totalRequestsFulfilled,
    int? idleHoursSaved,
  }) {
    return ImpactStatsState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      totalListings: totalListings ?? this.totalListings,
      totalRequestsFulfilled: totalRequestsFulfilled ?? this.totalRequestsFulfilled,
      idleHoursSaved: idleHoursSaved ?? this.idleHoursSaved,
    );
  }
}

class ImpactStatsNotifier extends StateNotifier<ImpactStatsState> {
  static const int _hoursSavedPerExchange = 8; // Assumed average hours saved per exchange

  ImpactStatsNotifier() : super(ImpactStatsState());

  Future<void> fetchImpactStats() async {
    state = state.copyWith(status: ImpactStatsStatus.loading, errorMessage: null);

    try {
      // Fetch total listings count
      final listingsResponse = await SupabaseService.client
          .from('listings')
          .select('id');
      
      final totalListings = listingsResponse.length;

      // Fetch total fulfilled requests count
      final requestsResponse = await SupabaseService.client
          .from('requests')
          .select('id')
          .eq('status', 'completed');
      
      final totalRequestsFulfilled = requestsResponse.length;

      // Calculate idle hours saved
      final idleHoursSaved = totalRequestsFulfilled * _hoursSavedPerExchange;

      state = state.copyWith(
        status: ImpactStatsStatus.loaded,
        totalListings: totalListings,
        totalRequestsFulfilled: totalRequestsFulfilled,
        idleHoursSaved: idleHoursSaved,
      );
    } catch (e) {
      state = state.copyWith(
        status: ImpactStatsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final impactStatsProvider =
    StateNotifierProvider<ImpactStatsNotifier, ImpactStatsState>((ref) {
  return ImpactStatsNotifier();
});
