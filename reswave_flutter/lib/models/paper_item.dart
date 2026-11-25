class PaperItem {
  final String id;
  final String userId;
  final String title;
  final List<String> authors;
  final String? doi;
  final String? url;
  final String? abstractText;
  final int? year;
  final List<String> tags;
  final String readingStatus; // Want to read / Reading / Read
  final String? privateNotes; // User-only confidential notes

  PaperItem({
    required this.id,
    required this.userId,
    required this.title,
    this.authors = const [],
    this.doi,
    this.url,
    this.abstractText,
    this.year,
    this.tags = const [],
    this.readingStatus = 'Want to read',
    this.privateNotes,
  });

  factory PaperItem.fromJson(Map<String, dynamic> json) {
    return PaperItem(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      authors: List<String>.from(json['authors'] ?? []),
      doi: json['doi'],
      url: json['url'],
      abstractText: json['abstract'],
      year: json['year'],
      tags: List<String>.from(json['tags'] ?? []),
      readingStatus: json['readingStatus'] ?? 'Want to read',
      privateNotes: json['privateNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'authors': authors,
      'doi': doi,
      'url': url,
      'abstract': abstractText,
      'year': year,
      'tags': tags,
      'readingStatus': readingStatus,
      'privateNotes': privateNotes,
    };
  }
}
