import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/supabase_service.dart';

enum ListingStatus {
  initial,
  uploading,
  submitting,
  success,
  error,
}

class ListingState {
  final ListingStatus status;
  final String? errorMessage;
  final File? selectedPhoto;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;

  ListingState({
    this.status = ListingStatus.initial,
    this.errorMessage,
    this.selectedPhoto,
    this.photoUrl,
    this.latitude,
    this.longitude,
  });

  ListingState copyWith({
    ListingStatus? status,
    String? errorMessage,
    File? selectedPhoto,
    String? photoUrl,
    double? latitude,
    double? longitude,
  }) {
    return ListingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      selectedPhoto: selectedPhoto ?? this.selectedPhoto,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class ListingNotifier extends StateNotifier<ListingState> {
  ListingNotifier() : super(ListingState());

  void selectPhoto(File photo) {
    state = state.copyWith(selectedPhoto: photo);
  }

  void setLocation(double latitude, double longitude) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  Future<void> submitListing({
    required String title,
    required String description,
    required String category,
    required String type,
  }) async {
    state = state.copyWith(status: ListingStatus.submitting, errorMessage: null);

    try {
      String? photoUrl;
      
      if (state.selectedPhoto != null) {
        state = state.copyWith(status: ListingStatus.uploading);
        final fileName = 'listing_${DateTime.now().millisecondsSinceEpoch}.jpg';
        photoUrl = await SupabaseService.uploadPhoto(state.selectedPhoto!, fileName);
      }

      await SupabaseService.createListing(
        title: title,
        description: description,
        category: category,
        type: type,
        photoUrl: photoUrl,
        latitude: state.latitude ?? 0.0,
        longitude: state.longitude ?? 0.0,
      );

      state = state.copyWith(
        status: ListingStatus.success,
        photoUrl: photoUrl,
      );
    } catch (e) {
      state = state.copyWith(
        status: ListingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = ListingState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final listingProvider = StateNotifierProvider<ListingNotifier, ListingState>((ref) {
  return ListingNotifier();
});
