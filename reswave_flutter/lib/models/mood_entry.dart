class MoodEntry {
  final String id;
  final String userId;
  final String mood; // Calm / Good / Motivated / Okay / Stressed / Overwhelmed / Low / Anxious
  final List<String> factors;
  final int? intensity; // Self-rating 1-5 (Explicitly non-clinical)
  final String? helpfulAction;
  final String? privateNote; // User-only private note
  final String createdAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    this.factors = const [],
    this.intensity,
    this.helpfulAction,
    this.privateNote,
    required this.createdAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      mood: json['mood'] ?? 'Okay',
      factors: List<String>.from(json['factors'] ?? []),
      intensity: json['intensity'],
      helpfulAction: json['helpfulAction'],
      privateNote: json['privateNote'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mood': mood,
      'factors': factors,
      'intensity': intensity,
      'helpfulAction': helpfulAction,
      'privateNote': privateNote,
      'createdAt': createdAt,
    };
  }
}

class SupportPost {
  final String id;
  final String authorId;
  final String authorDisplayName;
  final String category;
  final String text;
  final String displayMode;
  final String createdAt;

  SupportPost({
    required this.id,
    required this.authorId,
    required this.authorDisplayName,
    required this.category,
    required this.text,
    this.displayMode = 'Show profile name',
    required this.createdAt,
  });

  factory SupportPost.fromJson(Map<String, dynamic> json) {
    return SupportPost(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorDisplayName: json['authorDisplayName'] ?? 'Anonymous Member',
      category: json['category'] ?? 'Research stress',
      text: json['text'] ?? '',
      displayMode: json['displayMode'] ?? 'Show profile name',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

