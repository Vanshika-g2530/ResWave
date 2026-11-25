String _mentorText(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;

  if (value is String) return value;

  if (value is Iterable) {
    final List<String> result = [];

    for (final item in value) {
      final text = _mentorText(item);
      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    return result.join(', ');
  }

  if (value is Map) {
    final List<String> result = [];

    for (final item in value.values) {
      final text = _mentorText(item);
      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    return result.join(', ');
  }

  return value.toString();
}

List<String> _mentorList(dynamic value) {
  if (value == null) return <String>[];

  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is Iterable) {
    final List<String> result = [];

    for (final item in value) {
      final text = _mentorText(item);
      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    return result;
  }

  if (value is Map) {
    final List<String> result = [];

    for (final item in value.values) {
      final text = _mentorText(item);
      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    return result;
  }

  return <String>[_mentorText(value)];
}

int _mentorInt(dynamic value, [int fallback = 0]) {
  return int.tryParse(_mentorText(value)) ?? fallback;
}

bool _mentorBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = _mentorText(value).toLowerCase();

  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;

  return fallback;
}

class MentorProfileModel {
  final String userId;
  final bool mentorshipEnabled;
  final List<String> expertiseTags;
  final List<String> helpTypes;
  final List<String> menteeLevels;
  final List<String> formats;
  final String availability;
  final int maxCapacity;
  final int activeMenteesCount;
  final String preferredFrequency;
  final String timezone;
  final String visibility;

  MentorProfileModel({
    required this.userId,
    required this.mentorshipEnabled,
    required this.expertiseTags,
    required this.helpTypes,
    required this.menteeLevels,
    required this.formats,
    this.availability = 'Available',
    this.maxCapacity = 3,
    this.activeMenteesCount = 0,
    this.preferredFrequency = 'Bi-weekly',
    this.timezone = 'UTC',
    this.visibility = 'Public to members',
  });

  factory MentorProfileModel.fromJson(Map<String, dynamic> json) {
    return MentorProfileModel(
      userId: _mentorText(json['userId']),
      mentorshipEnabled: _mentorBool(json['mentorshipEnabled']),
      expertiseTags: _mentorList(json['expertiseTags']),
      helpTypes: _mentorList(json['helpTypes']),
      menteeLevels: _mentorList(json['menteeLevels']),
      formats: _mentorList(json['formats']),
      availability: _mentorText(json['availability'], 'Available'),
      maxCapacity: _mentorInt(json['maxCapacity'], 3),
      activeMenteesCount: _mentorInt(json['activeMenteesCount']),
      preferredFrequency: _mentorText(json['preferredFrequency'], 'Bi-weekly'),
      timezone: _mentorText(json['timezone'], 'UTC'),
      visibility: _mentorText(json['visibility'], 'Public to members'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'mentorshipEnabled': mentorshipEnabled,
      'expertiseTags': expertiseTags,
      'helpTypes': helpTypes,
      'menteeLevels': menteeLevels,
      'formats': formats,
      'availability': availability,
      'maxCapacity': maxCapacity,
      'activeMenteesCount': activeMenteesCount,
      'preferredFrequency': preferredFrequency,
      'timezone': timezone,
      'visibility': visibility,
    };
  }
}

class MentorRequestModel {
  final String id;
  final String menteeId;
  final String menteeName;
  final String? menteeRole;
  final String mentorId;
  final String mentorName;
  final String helpType;
  final String context;
  final String format;
  final String frequency;
  final String timezone;
  final String? questions;
  final String status;
  final String createdAt;

  MentorRequestModel({
    required this.id,
    required this.menteeId,
    required this.menteeName,
    this.menteeRole,
    required this.mentorId,
    required this.mentorName,
    required this.helpType,
    required this.context,
    required this.format,
    required this.frequency,
    required this.timezone,
    this.questions,
    required this.status,
    required this.createdAt,
  });

  factory MentorRequestModel.fromJson(Map<String, dynamic> json) {
    return MentorRequestModel(
      id: _mentorText(json['id']),
      menteeId: _mentorText(json['menteeId']),
      menteeName: _mentorText(json['menteeName']),
      menteeRole:
          json['menteeRole'] == null ? null : _mentorText(json['menteeRole']),
      mentorId: _mentorText(json['mentorId']),
      mentorName: _mentorText(json['mentorName']),
      helpType: _mentorText(json['helpType']),
      context: _mentorText(json['context']),
      format: _mentorText(json['format'], 'Remote'),
      frequency: _mentorText(json['frequency'], 'Bi-weekly'),
      timezone: _mentorText(json['timezone'], 'UTC'),
      questions:
          json['questions'] == null ? null : _mentorText(json['questions']),
      status: _mentorText(json['status'], 'Pending'),
      createdAt: _mentorText(json['createdAt']),
    );
  }
}
