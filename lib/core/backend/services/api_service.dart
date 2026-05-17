import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> registerDeviceWithAI({
    required String brand,
    required String model,
    required String serialNumber,
    required String imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'brand': brand,
          'model': model,
          'serial_number': serialNumber,
          'image_url': imageUrl,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to register device: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('Cannot connect to AI Server. Please check your network or ensure the backend is running.');
    } on TimeoutException {
      throw Exception('Connection to AI Server timed out. Please try again.');
    }
  }

  Future<Map<String, dynamic>> verifyDeviceWithAI({
    required String deviceId,
    required String qrHash,
    required String liveImageUrl,
    required int timestamp,
    List<double>? registeredFeatures,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/verify-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': deviceId,
          'qr_hash': qrHash,
          'live_image_url': liveImageUrl,
          'timestamp': timestamp,
          'registered_features': registeredFeatures,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to verify device: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('Cannot connect to AI Server. Please check your network or ensure the backend is running.');
    } on TimeoutException {
      throw Exception('Connection to AI Server timed out. Please try again.');
    }
  }

  Future<Map<String, dynamic>> checkQRWithAI({
    required String qrHash,
    required String qrData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/check-qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'qr_hash': qrHash,
          'qr_data': qrData,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to check QR: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('Cannot connect to AI Server. Please check your network or ensure the backend is running.');
    } on TimeoutException {
      throw Exception('Connection to AI Server timed out. Please try again.');
    }
  }
}

