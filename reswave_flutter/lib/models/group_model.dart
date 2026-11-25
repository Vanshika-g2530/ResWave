String _groupText(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;

  if (value is String) return value;

  if (value is Iterable) {
    final List<String> result = [];

    for (final item in value) {
      final text = _groupText(item);

      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    return result.join(', ');
  }

  if (value is Map) {
    final List<String> result = [];

    for (final item in value.values) {
      final text = _groupText(item);

      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    return result.join(', ');
  }

  return value.toString();
}

List<String> _groupList(dynamic value) {
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
      final text = _groupText(item);

      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    return result;
  }

  if (value is Map) {
    final List<String> result = [];

    for (final item in value.values) {
      final text = _groupText(item);

      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    return result;
  }

  return <String>[_groupText(value)];
}

int _groupInt(dynamic value, [int fallback = 1]) {
  return int.tryParse(_groupText(value)) ?? fallback;
}

class GroupModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String primaryDomain;
  final List<String> topics;
  final String purpose;
  final String membershipMode;
  final String visibility;
  final String rules;
  final int memberCount;
  final String status;
  final String createdAt;

  GroupModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.primaryDomain,
    required this.topics,
    required this.purpose,
    required this.membershipMode,
    required this.visibility,
    required this.rules,
    required this.memberCount,
    required this.status,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: _groupText(json['id']),
      ownerId: _groupText(json['ownerId']),
      title: _groupText(json['title']),
      description: _groupText(json['description']),
      primaryDomain: _groupText(
        json['primaryDomain'] ?? json['domain'],
      ),
      topics: _groupList(
        json['topics'] ?? json['topicTags'],
      ),
      purpose: _groupText(json['purpose']),
      membershipMode: _groupText(
        json['membershipMode'],
        'Open',
      ),
      visibility: _groupText(
        json['visibility'],
        'Discoverable',
      ),
      rules: _groupText(json['rules']),
      memberCount: _groupInt(json['memberCount']),
      status: _groupText(json['status'], 'Active'),
      createdAt: _groupText(json['createdAt']),
    );
  }
}
