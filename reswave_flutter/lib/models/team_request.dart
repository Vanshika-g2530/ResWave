String _teamText(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is Iterable)
    return value.map((e) => _teamText(e)).where((e) => e.isNotEmpty).join(', ');
  if (value is Map)
    return value.values
        .map((e) => _teamText(e))
        .where((e) => e.isNotEmpty)
        .join(', ');
  return value.toString();
}

List<String> _teamList(dynamic value) {
  if (value == null) return <String>[];
  if (value is String)
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  if (value is Iterable)
    return value.map((e) => _teamText(e)).where((e) => e.isNotEmpty).toList();
  if (value is Map)
    return value.values
        .map((e) => _teamText(e))
        .where((e) => e.isNotEmpty)
        .toList();
  return <String>[_teamText(value)];
}

int _teamInt(dynamic value, [int fallback = 0]) =>
    int.tryParse(_teamText(value)) ?? fallback;

class SkillRequirement {
  final String skill;
  final bool mustHave;

  SkillRequirement({required this.skill, this.mustHave = true});

  factory SkillRequirement.fromJson(Map<String, dynamic> json) {
    return SkillRequirement(
      skill: _teamText(json['skill']),
      mustHave: json['mustHave'] is bool ? json['mustHave'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() => {'skill': skill, 'mustHave': mustHave};
}

class TeamRequestModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String primaryDomain;
  final List<String> relatedDomains;
  final List<String> topics;
  final List<SkillRequirement> skillsNeeded;
  final List<String> rolesNeeded;
  final int membersNeeded;
  final int remainingCapacity;
  final String experiencePref;
  final String commitment;
  final String mode;
  final String status; // Open / Paused / Filled / Closed
  final List<String> applicationQuestions;

  TeamRequestModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.primaryDomain,
    this.relatedDomains = const [],
    required this.topics,
    required this.skillsNeeded,
    required this.rolesNeeded,
    required this.membersNeeded,
    required this.remainingCapacity,
    this.experiencePref = 'Any',
    this.commitment = 'Flexible',
    this.mode = 'Remote',
    this.status = 'Open',
    this.applicationQuestions = const [],
  });

  List<String> get mustHaveSkills => skillsNeeded
      .where((requirement) => requirement.mustHave)
      .map((requirement) => requirement.skill)
      .toList();

  factory TeamRequestModel.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skillsNeeded'] ?? json['mustHaveSkills'] ?? [];
    final skills = rawSkills is List
        ? rawSkills
            .map((e) => e is Map<String, dynamic>
                ? SkillRequirement.fromJson(e)
                : SkillRequirement(skill: _teamText(e)))
            .toList()
        : _teamList(rawSkills).map((e) => SkillRequirement(skill: e)).toList();
    return TeamRequestModel(
      id: _teamText(json['id']),
      ownerId: _teamText(json['ownerId']),
      title: _teamText(json['title']),
      description: _teamText(json['description']),
      primaryDomain: _teamText(json['primaryDomain'] ?? json['domain']),
      relatedDomains: _teamList(json['relatedDomains']),
      topics: _teamList(json['topics'] ?? json['targetTopicTags']),
      skillsNeeded: skills,
      rolesNeeded: _teamList(json['rolesNeeded'] ?? json['requiredRoles']),
      membersNeeded: _teamInt(json['membersNeeded'], 1),
      remainingCapacity:
          _teamInt(json['remainingCapacity'] ?? json['membersNeeded'], 1),
      experiencePref:
          _teamText(json['experiencePref'] ?? json['preferredLevel'], 'Any'),
      commitment: _teamText(
          json['commitment'] ?? json['expectedCommitmentHours'], 'Flexible'),
      mode: _teamText(json['mode'] ?? json['collaborationMode'], 'Remote'),
      status: _teamText(json['status'], 'Open'),
      applicationQuestions: _teamList(json['applicationQuestions']),
    );
  }
}

class ProjectModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> domainTags;
  final List<String> memberIds;
  final String status;
  final String? sourceTeamRequestId;

  ProjectModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    this.domainTags = const [],
    this.memberIds = const [],
    this.status = 'Active',
    this.sourceTeamRequestId,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      domainTags: List<String>.from(json['domainTags'] ?? []),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      status: json['status'] ?? 'Active',
      sourceTeamRequestId: json['sourceTeamRequestId'],
    );
  }
}
