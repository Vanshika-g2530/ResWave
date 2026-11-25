class OpportunityModel {
  final String id;
  final String type; // Conference / Workshop / Fellowship / Grant
  final String title;
  final String organiser;
  final String description;
  final List<String> tags;
  final String? startDate;
  final String? submissionDeadline;
  final String mode;
  final String? location;
  final String officialSourceUrl;
  final String lastVerifiedDate;

  OpportunityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.organiser,
    required this.description,
    this.tags = const [],
    this.startDate,
    this.submissionDeadline,
    this.mode = 'Online',
    this.location,
    required this.officialSourceUrl,
    required this.lastVerifiedDate,
  });

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    return OpportunityModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Conference',
      title: json['title'] ?? '',
      organiser: json['organiser'] ?? '',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      startDate: json['startDate'],
      submissionDeadline: json['submissionDeadline'],
      mode: json['mode'] ?? 'Online',
      location: json['location'],
      officialSourceUrl: json['officialSourceUrl'] ?? '',
      lastVerifiedDate: json['lastVerifiedDate'] ?? '',
    );
  }
}
