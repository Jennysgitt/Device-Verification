import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lightmode/core/backend/models/notification_model.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;
  
  Stream<List<NotificationModel>> getNotificationStream(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('sent_by', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  Stream<List<NotificationModel>> getSecurityAlertStream() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .map((json) => NotificationModel.fromJson(json))
            .where((n) => n.priority == 'high' || n.priority == 'emergency')
            .toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'medium',
    String category = 'general',
  }) async {
    await _client.from('notifications').insert({
      'sent_by': userId,
      'title': title,
      'message': message,
      'priority': priority,
      'category': category,
      'is_read': false,
    });
  }
}
