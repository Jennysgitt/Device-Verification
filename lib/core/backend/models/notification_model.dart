class NotificationModel {
  final String id;
  final String sentBy;
  final String title;
  final String message;
  final String priority;
  final String category;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.sentBy,
    required this.title,
    required this.message,
    required this.priority,
    required this.category,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      sentBy: json['sent_by'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'general',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sent_by': sentBy,
      'title': title,
      'message': message,
      'priority': priority,
      'category': category,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
