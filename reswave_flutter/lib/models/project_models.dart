class ProjectModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> domainTags;
  final List<String> memberIds;
  final String status;
  final String? startDate;

  ProjectModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.domainTags,
    required this.memberIds,
    required this.status,
    this.startDate,
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
      startDate: json['startDate'],
    );
  }
}

class ProjectTaskModel {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String? assigneeId;
  final String? assigneeName;
  final String priority;
  final String? dueDate;
  final String status;

  ProjectTaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.assigneeId,
    this.assigneeName,
    this.priority = 'Medium',
    this.dueDate,
    this.status = 'Not started',
  });

  factory ProjectTaskModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      assigneeId: json['assigneeId'],
      assigneeName: json['assigneeName'],
      priority: json['priority'] ?? 'Medium',
      dueDate: json['dueDate'],
      status: json['status'] ?? 'Not started',
    );
  }
}

class ProjectMilestoneModel {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String? dueDate;
  final String status;

  ProjectMilestoneModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.dueDate,
    this.status = 'Pending',
  });

  factory ProjectMilestoneModel.fromJson(Map<String, dynamic> json) {
    return ProjectMilestoneModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['dueDate'],
      status: json['status'] ?? 'Pending',
    );
  }
}
