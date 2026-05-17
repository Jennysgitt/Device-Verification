import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lightmode/core/backend/models/user_model.dart';
import 'package:lightmode/core/backend/models/device_model.dart';
import 'package:intl/intl.dart';

import 'package:lightmode/core/backend/models/notification_model.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;
  SupabaseClient get client => _client;

  Future<List<UserModel>> getUsers() async {
    final response = await _client.from('users').select();
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  // Auth Methods
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // User Methods
  Future<UserModel?> getUserRole(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<UserModel?> getUserByStudentId(String studentId) async {
    final studentIdUpper = studentId.toUpperCase().trim();
    
    final studentIdResponse = await _client
        .from('student_ids')
        .select('user_id, student_id')
        .eq('student_id', studentIdUpper)
        .maybeSingle();

    if (studentIdResponse == null) return null;

    final userResponse = await _client
        .from('users')
        .select()
        .eq('id', studentIdResponse['user_id'] as String)
        .maybeSingle();

    if (userResponse == null) return null;
    return UserModel.fromJson(userResponse);
  }

  Future<void> updateUserDepartment({
    required String userId,
    required String department,
  }) async {
    try {
      await _client.from('users').update({
        'department': department,
      }).eq('id', userId);
    } catch (e) {
      // Log error but don't rethrow to avoid blocking profile save
      debugPrint('Warning: Could not update department. It might be missing from the users table: $e');
    }
  }

  // Device Methods
  Future<List<DeviceModel>> getDevices({String? userId}) async {
    var query = _client.from('devices').select();
    
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    
    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => DeviceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getEnrichedDevices() async {
    try {
      // Stage 1: Try deep enrichment (Removed invalid 'location' column from verification_logs)
      final response = await _client
          .from('devices')
          .select('*, users(id, full_name), verification_logs(id, created_at, status, entry_type, latitude, longitude)')
          .order('created_at', ascending: false);
      
      if ((response as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(response);
      }

      // Stage 2: Fallback to partial enrichment 
      final partial = await _client
          .from('devices')
          .select('*, users(id, full_name)')
          .order('created_at', ascending: false);
      
      if ((partial as List).isNotEmpty) {
        return List<Map<String, dynamic>>.from(partial);
      }

      // Stage 3: Final fallback to raw devices
      final basic = await _client
          .from('devices')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(basic as List);
    } catch (e) {
      debugPrint('Enriched fetch fatal error: $e');
      try {
        final basic = await _client.from('devices').select().order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(basic as List);
      } catch (e2) {
        return [];
      }
    }
  }

  Future<DeviceModel> createDevice({
    required String userId,
    required String brand,
    required String model,
    required String serialNumber,
    required String imageUrl,
    String? deviceId,
    List<double>? features,
  }) async {
    final response = await _client.from('devices').insert({
      'user_id': userId,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'image_url': imageUrl,
      'device_id': deviceId,
      'ai_features': features,
      'status': 'pending', // Default to pending for admin verification
    }).select().single();

    final device = DeviceModel.fromJson(response);
    
    // Log Registration Audit
    await createAuditLog(
      action: 'DEVICE_REGISTERED',
      details: 'New ${device.brand} ${device.model} registered for user $userId',
      status: 'success',
    );

    return device;
  }

  Future<void> updateDeviceQrCode(
    String deviceId,
    String qrCodeUrl,
    String qrCodeHash,
  ) async {
    await _client.from('devices').update({
      'qr_code_url': qrCodeUrl,
      'qr_code_hash': qrCodeHash,
    }).eq('id', deviceId);
  }

  Future<void> reportDeviceStolen(String deviceId, {String? location}) async {
    await _client.from('devices').update({
      'status': 'stolen',
      'location': location,
    }).eq('id', deviceId);

    // Log Stolen Audit
    await createAuditLog(
      action: 'DEVICE_STOLEN',
      details: 'Device $deviceId reported stolen at ${location ?? "Unknown"}',
      status: 'warning',
    );
  }

  // Storage Methods
  Future<String> uploadImage(String path, List<int> fileBytes, {String bucket = 'device-images'}) async {
    final uint8List = Uint8List.fromList(fileBytes);
    await _client.storage
        .from(bucket)
        .uploadBinary(path, uint8List);

    final publicUrl = _client.storage
        .from(bucket)
        .getPublicUrl(path);
    
    return publicUrl;
  }

  // User Profile Methods
  Future<void> updateUserProfile({
    required String userId,
    String? email,
    String? profilePictureUrl,
    String? fullName,
    String? role,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (email != null) {
      updateData['email'] = email;
    }
    
    if (profilePictureUrl != null) {
      updateData['profile_picture_url'] = profilePictureUrl;
    }
    
    if (fullName != null) {
      updateData['full_name'] = fullName;
    }

    if (role != null) {
      updateData['role'] = role;
    }

    if (updateData.isNotEmpty) {
      await _client
          .from('users')
          .update(updateData) 
          .eq('id', userId);
    }
  }

  Future<List<Map<String, dynamic>>> getEnrichedVerificationLogs({
    int limit = 100,
  }) async {
    final response = await _client
        .from('verification_logs')
        .select('*, devices(*, users(*, student_ids(student_id)))')
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getStudentVerificationLogs({
    required String userId,
    int limit = 50,
  }) async {
    final devicesRes = await _client
        .from('devices')
        .select('id')
        .eq('user_id', userId);
    
    final deviceIds = (devicesRes as List).map((d) => d['id'] as String).toList();
    
    if (deviceIds.isEmpty) return [];

    final response = await _client
        .from('verification_logs')
        .select('*, devices(*)')
        .inFilter('device_id', deviceIds)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getStudentDashboardActivity({
    required String userId,
    int limit = 10,
  }) async {
    // 1. Get Verification Logs
    final logs = await getStudentVerificationLogs(userId: userId, limit: limit);
    
    // 2. Get Device Registrations
    final devicesRes = await _client
        .from('devices')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    
    final List<Map<String, dynamic>> activity = [];
    
    // Add scans
    for (var log in logs) {
      activity.add({
        'type': 'scan',
        'created_at': log['created_at'],
        'status': log['status'],
        'brand': log['devices']?['brand'] ?? 'Device',
        'model': log['devices']?['model'] ?? '',
        'location': log['location'] ?? 'Gate',
        'entry_type': log['entry_type'] ?? 'access',
      });
    }
    
    // Add registrations
    for (var dev in (devicesRes as List)) {
      activity.add({
        'type': 'registration',
        'created_at': dev['created_at'],
        'status': 'success',
        'brand': dev['brand'],
        'model': dev['model'],
        'location': 'Registry',
        'entry_type': 'registration',
      });
    }
    
    // Sort by date desc
    activity.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    
    return activity.take(limit).toList();
  }


  Future<Map<String, dynamic>?> getDeviceDetailWithOwner(String deviceId) async {
    final response = await _client
        .from('devices')
        .select('*, users(*, student_ids(student_id)), verification_logs(*)')
        .eq('id', deviceId)
        .maybeSingle();

    return response;
  }

  Future<void> updateDeviceStatus(String deviceId, String status, {String? location}) async {
    await _client.from('devices').update({
      'status': status,
      'location': location,
    }).eq('id', deviceId);
  }

  Future<void> verifyDevice(String deviceId) async {
    await _client.from('devices').update({
      'status': 'verified',
    }).eq('id', deviceId);
    
    // Log the verification
    await createAuditLog(
      action: 'DEVICE_VERIFIED',
      details: 'Device $deviceId verified by administrator.',
      status: 'success',
    );
  }

  /// Batch-flags all registered devices for a user as 'stolen'.
  /// Called during the student SOS "Report Stolen Device" flow.
  Future<void> flagUserDevicesAsStolen(String userId) async {
    await _client
        .from('devices')
        .update({
          'status': 'stolen',
          'location': 'Reported stolen by owner',
        })
        .eq('user_id', userId)
        .neq('status', 'stolen'); // Don't re-update already-flagged devices

    await createAuditLog(
      action: 'DEVICE_STOLEN_REPORTED',
      details: 'All devices for user $userId flagged as stolen via SOS.',
      status: 'critical',
    );
  }

  Future<void> ensureDeviceQrHash(String deviceId, String serialNumber) async {
    final device = await _client.from('devices').select('qr_code_hash').eq('id', deviceId).single();
    if (device['qr_code_hash'] == null) {
      final newHash = 'SGC-${serialNumber}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      await _client.from('devices').update({'qr_code_hash': newHash}).eq('id', deviceId);
    }
  }

  Future<String> createVerificationLog({
    required String deviceId,
    String? officerId,
    required String status,
    double? aiScore,
    double? imageMatchScore,
    bool? qrValidity,
    String entryType = 'entry',
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.from('verification_logs').insert({
      'device_id': deviceId,
      'officer_id': officerId,
      'status': status,
      'ai_score': aiScore,
      'image_match_score': imageMatchScore,
      'qr_validity': qrValidity,
      'entry_type': entryType,
      'latitude': latitude,
      'longitude': longitude,
    }).select('id').single();
    
    return response['id'] as String;
  }

  Future<void> updateScanResult({
    required String logId,
    required String status,
    required double aiScore,
  }) async {
    await _client.from('verification_logs').update({
      'status': status,
      'ai_score': aiScore,
      'image_match_score': aiScore,
    }).eq('id', logId);
  }

  Future<Map<String, int>> getOfficerStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    final scansToday = await _client
        .from('verification_logs')
        .select('id')
        .gte('created_at', startOfDay);
    
    final flaggedToday = await _client
        .from('verification_logs')
        .select('id')
        .gte('created_at', startOfDay)
        .neq('status', 'verified');

    return {
      'scans': (scansToday as List).length,
      'flagged': (flaggedToday as List).length,
    };
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();

    // 1. Total Registered Devices
    final totalDevicesResponse = await _client
        .from('devices')
        .select('id');
    final totalDevices = (totalDevicesResponse as List).length;

    // 2. Active Security Alerts (Stolen devices)
    final stolenDevicesResponse = await _client
        .from('devices')
        .select('id')
        .eq('status', 'stolen');
    final activeAlerts = (stolenDevicesResponse as List).length;

    // 3. Verified Scans Today
    final verifiedTodayResponse = await _client
        .from('verification_logs')
        .select('id')
        .gte('created_at', startOfToday)
        .eq('status', 'verified');
    final verifiedToday = (verifiedTodayResponse as List).length;

    // 4. Suspicious Activity Today (Flagged/Failed)
    final suspiciousTodayResponse = await _client
        .from('verification_logs')
        .select('id')
        .gte('created_at', startOfToday)
        .inFilter('status', ['flagged', 'failed']);
    final suspiciousToday = (suspiciousTodayResponse as List).length;

    return {
      'totalDevices': totalDevices,
      'activeAlerts': activeAlerts,
      'verifiedToday': verifiedToday,
      'suspiciousToday': suspiciousToday,
    };
  }

  Future<Map<String, int>> getScanVolumeStats() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).toIso8601String();

    final response = await _client
        .from('verification_logs')
        .select('created_at')
        .gte('created_at', sevenDaysAgo);

    final Map<String, int> dailyCounts = {};
    for (var i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('MMM d').format(date);
      dailyCounts[dateStr] = 0;
    }

    for (final item in (response as List)) {
      final date = DateTime.parse(item['created_at']);
      final dateStr = DateFormat('MMM d').format(date);
      if (dailyCounts.containsKey(dateStr)) {
        dailyCounts[dateStr] = (dailyCounts[dateStr] ?? 0) + 1;
      }
    }

    return dailyCounts;
  }

  Future<Map<String, int>> getDeviceBrandBreakdown() async {
    final response = await _client.from('devices').select('brand');
    final Map<String, int> breakdown = {};
    for (final item in (response as List)) {
      final brand = item['brand']?.toString() ?? 'Other';
      breakdown[brand] = (breakdown[brand] ?? 0) + 1;
    }
    return breakdown;
  }

  Future<void> logActivity({
    required String activityType,
    String? officerId,
    String status = 'info',
  }) async {
    try {
      await _client.from('audit_logs').insert({
        'action': activityType,
        'details': 'System Event: $activityType',
        'status': status,
        'admin_id': officerId, // Overload admin_id with officer_id if applicable
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Logging failed: $e');
    }
  }

  Future<void> createAuditLog({
    required String action,
    required String details,
    String status = 'info',
  }) async {
    try {
      await _client.from('audit_logs').insert({
        'action': action,
        'details': details,
        'status': status,
        'admin_id': _client.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Audit logging failed: $e');
    }
  }

  Future<Map<String, dynamic>> getAdminDashboardData() async {
    final stats = await getAdminStats();
    final volume = await getScanVolumeStats();
    final breakdown = await getDeviceBrandBreakdown();

    // Fetch and merge logs from both sources
    final recentVerifications = await getEnrichedVerificationLogs(limit: 10);
    
    List<Map<String, dynamic>> recentAudits = [];
    try {
      final recentAuditsRaw = await _client
          .from('audit_logs')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);
      
      recentAudits = (recentAuditsRaw as List).map((audit) => {
        'id': audit['id'],
        'device_id': '00000000-0000-0000-0000-000000000000', // Marker
        'status': audit['status']?.toString().toUpperCase() ?? 'INFO',
        'entry_type': audit['action']?.toString().toUpperCase() ?? 'SYSTEM',
        'created_at': audit['created_at'],
        'devices': null, // Audit logs don't have associated devices directly here
      }).toList();
    } catch (e) {
      debugPrint('Audit logs not available (table missing): $e');
    }

    // Combine and re-sort
    final allLogs = [...recentVerifications, ...recentAudits];
    allLogs.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    
    return {
      'stats': stats,
      'recentActivity': allLogs.take(10).toList(),
      'volume': volume,
      'breakdown': breakdown,
    };
  }

  Future<Map<String, dynamic>> getOfficerDashboardData() async {
    final stats = await getOfficerStats();
    final recentLogs = await getEnrichedVerificationLogs(limit: 5);
    return {
      'stats': stats,
      'recentActivity': recentLogs,
    };
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await _client
        .from('notifications')
        .select()
        .eq('sent_by', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String priority = 'medium',
    String category = 'general',
  }) async {
    try {
      await _client.from('notifications').insert({
        'sent_by': userId,
        'title': title,
        'message': message,
        'priority': priority,
        'category': category,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    // Note: To routing SOS alerts to security personnel, we want them to see 
    // any notification with 'security_alert' category or ones sent specifically to them.
    // For simplicity in the realtime stream filter, we stream and then the provider 
    // filtered view can be used, but here we provide a broader stream for security personnel.
    
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
        // Filtering will be handled more granularly if needed, 
        // but this ensures security personnel 'hear' all broadcasts.
  }
}

