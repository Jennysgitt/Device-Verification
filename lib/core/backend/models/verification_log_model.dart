class VerificationLogModel {
  final String id;
  final String deviceId;
  final String? officerId;
  final String status;
  final double? aiScore;
  final double? imageMatchScore;
  final bool? qrValidity;
  final String entryType;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  VerificationLogModel({
    required this.id,
    required this.deviceId,
    this.officerId,
    required this.status,
    this.aiScore,
    this.imageMatchScore,
    this.qrValidity,
    required this.entryType,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory VerificationLogModel.fromJson(Map<String, dynamic> json) {
    return VerificationLogModel(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      officerId: json['officer_id'] as String?,
      status: json['status'] as String,
      aiScore: (json['ai_score'] as num?)?.toDouble(),
      imageMatchScore: (json['image_match_score'] as num?)?.toDouble(),
      qrValidity: json['qr_validity'] as bool?,
      entryType: json['entry_type'] as String? ?? 'entry',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

