class ConversationModel {
  final String id;
  final List<String> participants;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserRole;
  final String? otherUserInstitution;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserRole,
    this.otherUserInstitution,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      otherUserId: json['otherUserId'] ?? '',
      otherUserName: json['otherUserName'] ?? 'Academic Peer',
      otherUserRole: json['otherUserRole'],
      otherUserInstitution: json['otherUserInstitution'],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final String? attachmentUrl;
  final bool read;
  final String createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.attachmentUrl,
    required this.read,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      attachmentUrl: json['attachmentUrl'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
