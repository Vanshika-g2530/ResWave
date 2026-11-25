class ConnectionModel {
  final String connectionId;
  final String connectedAt;
  final String userId;
  final String displayName;
  final String role;
  final String? institution;
  final String? headline;
  final String? country;

  ConnectionModel({
    required this.connectionId,
    required this.connectedAt,
    required this.userId,
    required this.displayName,
    required this.role,
    this.institution,
    this.headline,
    this.country,
  });

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      connectionId: json['connectionId'] ?? '',
      connectedAt: json['connectedAt'] ?? '',
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      role: json['role'] ?? '',
      institution: json['institution'],
      headline: json['headline'],
      country: json['country'],
    );
  }
}

class ConnectionRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderRole;
  final String? senderInstitution;
  final String receiverId;
  final String receiverName;
  final String? receiverRole;
  final String? receiverInstitution;
  final String? note;
  final String status;
  final String createdAt;

  ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderRole,
    this.senderInstitution,
    required this.receiverId,
    required this.receiverName,
    this.receiverRole,
    this.receiverInstitution,
    this.note,
    required this.status,
    required this.createdAt,
  });

  factory ConnectionRequestModel.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderRole: json['senderRole'],
      senderInstitution: json['senderInstitution'],
      receiverId: json['receiverId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      receiverRole: json['receiverRole'],
      receiverInstitution: json['receiverInstitution'],
      note: json['note'],
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class FollowerModel {
  final String userId;
  final String displayName;
  final String role;
  final String? institution;
  final String? headline;
  final String followedAt;
  final bool isFollowing;

  FollowerModel({
    required this.userId,
    required this.displayName,
    required this.role,
    this.institution,
    this.headline,
    required this.followedAt,
    required this.isFollowing,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) {
    return FollowerModel(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? '',
      role: json['role'] ?? '',
      institution: json['institution'],
      headline: json['headline'],
      followedAt: json['followedAt'] ?? '',
      isFollowing: json['isFollowing'] ?? false,
    );
  }
}

class NetworkSummaryModel {
  final int connectionsCount;
  final int followersCount;
  final int followingCount;
  final int pendingReceivedCount;

  NetworkSummaryModel({
    required this.connectionsCount,
    required this.followersCount,
    required this.followingCount,
    required this.pendingReceivedCount,
  });

  factory NetworkSummaryModel.fromJson(Map<String, dynamic> json) {
    return NetworkSummaryModel(
      connectionsCount: json['connectionsCount'] ?? 0,
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      pendingReceivedCount: json['pendingReceivedCount'] ?? 0,
    );
  }
}
