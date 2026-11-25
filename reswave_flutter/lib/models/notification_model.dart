class NotificationModel {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final String? targetType;
  final String? targetId;
  final bool read;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.targetType,
    this.targetId,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      recipientId: json['recipientId'] ?? '',
      type: json['type'] ?? 'General',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetType: json['targetType'],
      targetId: json['targetId'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
