import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';

class NotificationProvider with ChangeNotifier {
  final SupabaseService _supabaseService;
  final String _userId;
  
  List<NotificationModel> _notifications = [];
  StreamSubscription? _subscription;
  bool _isLoading = true;

  NotificationProvider(this._supabaseService, this._userId) {
    _initRealtimeListener();
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  void _initRealtimeListener() {
    _isLoading = true;
    notifyListeners();

    _subscription = _supabaseService.streamNotifications(_userId).listen((data) {
      _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Notification Stream Error: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseService.markNotificationAsRead(notificationId);
      // Realtime listener will handle the UI update
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    for (var notification in _notifications.where((n) => !n.isRead)) {
      await markAsRead(notification.id);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
