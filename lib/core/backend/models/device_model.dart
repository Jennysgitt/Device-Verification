class DeviceModel {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final String serialNumber;
  final String? imageUrl;
  final String? qrCodeUrl;
  final String? qrCodeHash;
  final String? deviceId;
  final List<double>? features;
  final String status;
  final String? location;
  final DateTime createdAt;

  DeviceModel({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.serialNumber,
    this.imageUrl,
    this.qrCodeUrl,
    this.qrCodeHash,
    this.deviceId,
    this.features,
    this.status = 'pending',
    this.location,
    required this.createdAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      serialNumber: json['serial_number'] as String,
      imageUrl: json['image_url'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      qrCodeHash: json['qr_code_hash'] as String?,
      deviceId: json['device_id'] as String?,
      features: (json['ai_features'] as List?)?.map((e) => (e as num).toDouble()).toList(),
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'image_url': imageUrl,
      'qr_code_url': qrCodeUrl,
      'qr_code_hash': qrCodeHash,
      'device_id': deviceId,
      'ai_features': features,
      'status': status,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

