import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

class AppNotification {
  final String id;
  final String type;
  final String message;
  final String? relatedRequestId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.relatedRequestId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      relatedRequestId: json['related_request_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState {
  final NotificationsStatus status;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? errorMessage;

  NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(NotificationsState());

  String? get _userId => SupabaseService.auth.currentUser?.id;

  Future<void> fetchUnreadCount() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final response = await SupabaseService.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      final count = (response as List).length;
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // Keep previous count on error
    }
  }

  Future<void> fetchNotifications() async {
    final userId = _userId;
    if (userId == null) return;

    state = state.copyWith(status: NotificationsStatus.loading);

    try {
      final response = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      final updated = state.notifications.map((n) {
        if (n.id == notificationId) {
          return AppNotification(
            id: n.id,
            type: n.type,
            message: n.message,
            relatedRequestId: n.relatedRequestId,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      );
    } catch (_) {
      // Silently fail — navigation still proceeds
    }
  }

  Future<String?> fetchListingIdForRequest(String requestId) async {
    try {
      final response = await SupabaseService.client
          .from('requests')
          .select('listing_id')
          .eq('id', requestId)
          .maybeSingle();

      return response?['listing_id'] as String?;
    } catch (_) {
      return null;
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
