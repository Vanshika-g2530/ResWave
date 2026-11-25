class FeedPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorHeadline;
  final String text;
  final String postType;
  final List<String> domainTags;
  final String? attachmentUrl;
  final String audience;
  final int reactionCount;
  final int commentCount;
  final String createdAt;

  FeedPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorHeadline,
    required this.text,
    required this.postType,
    required this.domainTags,
    this.attachmentUrl,
    this.audience = 'Members',
    required this.reactionCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    return FeedPostModel(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Scholar',
      authorHeadline: json['authorHeadline'],
      text: json['text'] ?? '',
      postType: json['postType'] ?? 'Research update',
      domainTags: List<String>.from(json['domainTags'] ?? []),
      attachmentUrl: json['attachmentUrl'],
      audience: json['audience'] ?? 'Members',
      reactionCount: json['reactionCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorRole;
  final String text;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorRole,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Scholar',
      authorRole: json['authorRole'],
      text: json['text'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
