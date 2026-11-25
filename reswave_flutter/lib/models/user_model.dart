class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? headline;
  final String? bio;
  final String country;
  final String? city;
  final String? institution;
  final String? department;
  final String visibility;
  final bool discoverable;
  final String preferredCollaborationMode;
  final bool emailVerified;
  final bool isAdmin;
  final String accountStatus;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.headline,
    this.bio,
    required this.country,
    this.city,
    this.institution,
    this.department,
    this.visibility = 'Public to members',
    this.discoverable = false,
    this.preferredCollaborationMode = 'No preference',
    this.emailVerified = false,
    this.isAdmin = false,
    this.accountStatus = 'active',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      role: json['role'] ?? 'Student (UG/PG)',
      headline: json['headline'],
      bio: json['bio'],
      country: json['country'] ?? '',
      city: json['city'],
      institution: json['institution'],
      department: json['department'],
      visibility: json['visibility'] ?? 'Public to members',
      discoverable: json['discoverable'] ?? false,
      preferredCollaborationMode: json['preferredCollaborationMode'] ?? 'No preference',
      emailVerified: json['emailVerified'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
      accountStatus: json['accountStatus'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'headline': headline,
      'bio': bio,
      'country': country,
      'city': city,
      'institution': institution,
      'department': department,
      'visibility': visibility,
      'discoverable': discoverable,
      'preferredCollaborationMode': preferredCollaborationMode,
      'emailVerified': emailVerified,
      'isAdmin': isAdmin,
      'accountStatus': accountStatus,
    };
  }
}
