class LearningResource {
  final String id;
  final String title;
  final String category;
  final List<String> domainTags;
  final String level;
  final String format;
  final String summary;
  final String contentOrUrl;
  final String sourceName;
  final String sourceUrl;
  final int durationMinutes;
  final String authorOrEditor;
  final String reviewedDate;
  final String status;

  LearningResource({
    required this.id,
    required this.title,
    required this.category,
    this.domainTags = const [],
    required this.level,
    required this.format,
    required this.summary,
    required this.contentOrUrl,
    required this.sourceName,
    required this.sourceUrl,
    this.durationMinutes = 15,
    required this.authorOrEditor,
    required this.reviewedDate,
    this.status = 'Published',
  });

  factory LearningResource.fromJson(Map<String, dynamic> json) {
    return LearningResource(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      domainTags: List<String>.from(json['domainTags'] ?? []),
      level: json['level'] ?? 'Beginner',
      format: json['format'] ?? 'Article',
      summary: json['summary'] ?? '',
      contentOrUrl: json['contentOrUrl'] ?? '',
      sourceName: json['sourceName'] ?? '',
      sourceUrl: json['sourceUrl'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 15,
      authorOrEditor: json['authorOrEditor'] ?? '',
      reviewedDate: json['reviewedDate'] ?? '',
      status: json['status'] ?? 'Published',
    );
  }
}
