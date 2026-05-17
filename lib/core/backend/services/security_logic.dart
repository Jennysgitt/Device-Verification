import 'package:lightmode/core/backend/services/supabase_service.dart';
import 'package:lightmode/core/backend/services/notification_service.dart';
import 'package:lightmode/core/backend/models/device_model.dart';

class SecurityLogic {
  final SupabaseService _supabaseService;
  final NotificationService _notificationService;

  SecurityLogic(this._supabaseService, this._notificationService);

  /// Checks for suspicious activity after a scan event
  Future<void> evaluateVerificationEvent({
    required DeviceModel device,
    required String status,
    required bool qrValidity,
    required double imageMatchScore,
    String? location,
  }) async {
    if (device.status == 'stolen') {
      await _notificationService.sendNotification(
        userId: device.userId,
        title: 'STOLEN DEVICE DETECTED',
        message: 'Your ${device.brand} ${device.model} was just scanned at a campus gate. Security has been alerted.',
        priority: 'emergency',
        category: 'security_alert',
      );
    }

    if (qrValidity && status == 'suspicious' && imageMatchScore < 0.6) {
      await _notificationService.sendNotification(
        userId: device.userId,
        title: 'Unauthorized Hardware Alert',
        message: 'A verification attempt for your ${device.brand} was flagged. The hardware scanned did not match your registered device.',
        priority: 'high',
        category: 'security_alert',
      );
    }

    final recentLogs = await _supabaseService.client
        .from('verification_logs')
        .select()
        .eq('device_id', device.id)
        .order('created_at', ascending: false)
        .limit(2);

    if (recentLogs.length >= 2) {
      final lastLog = recentLogs[1];
      final lastTime = DateTime.parse(lastLog['created_at']);
      final now = DateTime.now();
      
      if (now.difference(lastTime).inMinutes < 2 && lastLog['entry_type'] == 'entry') {
        await _notificationService.sendNotification(
          userId: device.userId,
          title: 'Suspicious Activity Detected',
          message: 'Multiple entries detected for ${device.brand} within a short window. Possible QR sharing or unauthorized duplication.',
          priority: 'high',
          category: 'security_alert',
        );
      }
    }
  }
}
