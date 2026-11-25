class ResearchInterest {
  final String id;
  final String userId;
  final String domainId;
  final String subdomainId;
  final List<String> topicTags;
  final List<String> keywords;
  final String proficiency;
  final String status;
  final List<String> skills;
  final List<String> methods;
  final List<String> goals;
  final String availability;
  final String visibility;

  ResearchInterest({
    required this.id,
    required this.userId,
    required this.domainId,
    required this.subdomainId,
    required this.topicTags,
    this.keywords = const [],
    this.proficiency = 'Beginner',
    this.status = 'Exploring',
    this.skills = const [],
    this.methods = const [],
    required this.goals,
    this.availability = 'Available',
    this.visibility = 'Visible to members',
  });

  factory ResearchInterest.fromJson(Map<String, dynamic> json) {
    return ResearchInterest(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      domainId: json['domainId'] ?? '',
      subdomainId: json['subdomainId'] ?? '',
      topicTags: List<String>.from(json['topicTags'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      proficiency: json['proficiency'] ?? 'Beginner',
      status: json['status'] ?? 'Exploring',
      skills: List<String>.from(json['skills'] ?? []),
      methods: List<String>.from(json['methods'] ?? []),
      goals: List<String>.from(json['goals'] ?? ['Learn']),
      availability: json['availability'] ?? 'Available',
      visibility: json['visibility'] ?? 'Visible to members',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'domainId': domainId,
      'subdomainId': subdomainId,
      'topicTags': topicTags,
      'keywords': keywords,
      'proficiency': proficiency,
      'status': status,
      'skills': skills,
      'methods': methods,
      'goals': goals,
      'availability': availability,
      'visibility': visibility,
    };
  }
}
