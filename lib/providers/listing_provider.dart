import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
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
  final Uint8List? selectedPhotoBytes;
  final String? selectedPhotoName;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;

  ListingState({
    this.status = ListingStatus.initial,
    this.errorMessage,
    this.selectedPhotoBytes,
    this.selectedPhotoName,
    this.photoUrl,
    this.latitude,
    this.longitude,
  });

  ListingState copyWith({
    ListingStatus? status,
    String? errorMessage,
    Uint8List? selectedPhotoBytes,
    String? selectedPhotoName,
    String? photoUrl,
    double? latitude,
    double? longitude,
  }) {
    return ListingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      selectedPhotoBytes: selectedPhotoBytes ?? this.selectedPhotoBytes,
      selectedPhotoName: selectedPhotoName ?? this.selectedPhotoName,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class ListingNotifier extends StateNotifier<ListingState> {
  ListingNotifier() : super(ListingState());

  void selectPhoto(Uint8List bytes, String name) {
    state = state.copyWith(selectedPhotoBytes: bytes, selectedPhotoName: name);
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
      
      if (state.selectedPhotoBytes != null && state.selectedPhotoName != null) {
        state = state.copyWith(status: ListingStatus.uploading);
        photoUrl = await SupabaseService.uploadPhotoBytes(
          bytes: state.selectedPhotoBytes!,
          fileName: state.selectedPhotoName!,
        );
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
