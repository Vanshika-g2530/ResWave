class DomainModel {
  final String id;
  final String name;
  final String shortDescription;
  final String beginnerExplanation;
  final List<String> subdomains;
  final List<String> keywords;
  final List<String> subjectTags;
  final List<String> problemTags;
  final List<String> workStyleTags;
  final List<String> skillTags;
  final List<String> goalTags;
  final List<String> sampleResearchQuestions;
  final List<String> commonMethods;
  final String status;

  DomainModel({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.beginnerExplanation,
    this.subdomains = const [],
    this.keywords = const [],
    this.subjectTags = const [],
    this.problemTags = const [],
    this.workStyleTags = const [],
    this.skillTags = const [],
    this.goalTags = const [],
    this.sampleResearchQuestions = const [],
    this.commonMethods = const [],
    this.status = 'Published',
  });

  factory DomainModel.fromJson(Map<String, dynamic> json) {
    return DomainModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      beginnerExplanation: json['beginnerExplanation'] ?? '',
      subdomains: List<String>.from(json['subdomains'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      subjectTags: List<String>.from(json['subjectTags'] ?? []),
      problemTags: List<String>.from(json['problemTags'] ?? []),
      workStyleTags: List<String>.from(json['workStyleTags'] ?? []),
      skillTags: List<String>.from(json['skillTags'] ?? []),
      goalTags: List<String>.from(json['goalTags'] ?? []),
      sampleResearchQuestions:
          List<String>.from(json['sampleResearchQuestions'] ?? []),
      commonMethods: List<String>.from(json['commonMethods'] ?? []),
      status: json['status'] ?? 'Published',
    );
  }
}

class DomainRecommendationResult {
  final String domainId;
  final String name;
  final String description;
  final String fitBand;
  final double score;
  final List<String> reasons;
  final List<String> sampleTopics;
  final List<String> requiredSkills;
  final List<String> beginnerResources;
  final List<String> sampleQuestions;
  final List<String> commonMethods;
  final List<String> relatedGroups;

  DomainRecommendationResult({
    required this.domainId,
    required this.name,
    this.description = '',
    required this.fitBand,
    required this.score,
    required this.reasons,
    required this.sampleTopics,
    required this.requiredSkills,
    required this.beginnerResources,
    this.sampleQuestions = const [],
    this.commonMethods = const [],
    this.relatedGroups = const [],
  });

  factory DomainRecommendationResult.fromJson(Map<String, dynamic> json) {
    return DomainRecommendationResult(
      domainId: json['domainId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      fitBand: json['fitBand'] ?? 'Explore',
      score: (json['score'] as num?)?.toDouble() ?? 50.0,
      reasons: List<String>.from(json['reasons'] ?? []),
      sampleTopics: List<String>.from(json['sampleTopics'] ?? []),
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      beginnerResources: List<String>.from(json['beginnerResources'] ?? []),
      sampleQuestions: List<String>.from(json['sampleQuestions'] ?? []),
      commonMethods: List<String>.from(json['commonMethods'] ?? []),
      relatedGroups: List<String>.from(json['relatedGroups'] ?? []),
    );
  }
}
