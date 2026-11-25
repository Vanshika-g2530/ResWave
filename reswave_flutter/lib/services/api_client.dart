import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/research_interest.dart';
import '../models/domain_model.dart';
import '../models/learning_resource.dart';
import '../models/paper_item.dart';
import '../models/team_request.dart' hide ProjectModel;
import '../models/mood_entry.dart';
import '../models/opportunity.dart';
import '../models/network_models.dart';
import '../models/mentor_models.dart';
import '../models/feed_models.dart';
import '../models/message_models.dart';
import '../models/group_model.dart';
import '../models/project_models.dart';
import '../models/notification_model.dart';

class ResWaveApiException implements Exception {
  final String message;
  final int? statusCode;
  ResWaveApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ResWaveApiService {
  static final ResWaveApiService _instance = ResWaveApiService._internal();
  factory ResWaveApiService() => _instance;
  ResWaveApiService._internal();

  // Android emulator points to host localhost at 10.0.2.2; standard localhost for local runners
  static String baseUrl = 'http://192.168.29.204:8000';

  String? _token;
  String? _firebaseUid;
  UserModel? currentUser;

  bool get isAuthenticated => currentUser != null && _token != null;

  void setAuth(UserModel user, String token, {String? firebaseUid}) {
    currentUser = user;
    _token = token;
    _firebaseUid = firebaseUid;
  }

  void setFirebaseCredentials(String uid, String idToken) {
    _firebaseUid = uid;
    _token = idToken;
  }

  void logout() {
    currentUser = null;
    _token = null;
    _firebaseUid = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        if (_firebaseUid != null) 'X-Firebase-UID': _firebaseUid!,
      };

  // ==================== Auth & Profile ====================
  Future<UserModel> loginWithFirebase({
    required String email,
    required String firebaseUid,
    required String firebaseIdToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $firebaseIdToken',
        'X-Firebase-UID': firebaseUid,
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      if (user.uid != firebaseUid) {
        throw ResWaveApiException(
            'The ResWave profile does not match this Firebase account.');
      }
      setAuth(user, firebaseIdToken, firebaseUid: firebaseUid);
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw ResWaveApiException(
          error['detail'] ?? 'Login failed', response.statusCode);
    }
  }

  Future<UserModel> signupWithFirebase({
    required String name,
    required String email,
    required String role,
    required String country,
    String? city,
    String? institution,
    String? department,
    required String firebaseUid,
    required String firebaseIdToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/v1/auth/signup'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $firebaseIdToken',
        'X-Firebase-UID': firebaseUid,
      },
      body: jsonEncode({
        'displayName': name,
        'email': email,
        'role': role,
        'country': country,
        'city': city,
        'institution': institution,
        'department': department,
        'termsAccepted': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      if (user.uid != firebaseUid) {
        throw ResWaveApiException(
            'The ResWave profile does not match this Firebase account.');
      }
      setAuth(user, firebaseIdToken, firebaseUid: firebaseUid);
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw ResWaveApiException(
          error['detail'] ?? 'Registration failed', response.statusCode);
    }
  }

  Future<UserModel> getMyProfile() async {
    final res =
        await http.get(Uri.parse('$baseUrl/v1/users/me'), headers: _headers);
    if (res.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(res.body));
      currentUser = user;
      return user;
    } else {
      throw ResWaveApiException('Failed to load profile', res.statusCode);
    }
  }

  Future<UserModel> updateMyProfile(Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$baseUrl/v1/users/me'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    if (res.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(res.body));
      currentUser = user;
      return user;
    } else {
      throw ResWaveApiException('Failed to update profile', res.statusCode);
    }
  }

  Future<void> deleteMyAccount() async {
    final res =
        await http.delete(Uri.parse('$baseUrl/v1/users/me'), headers: _headers);
    if (res.statusCode == 200) {
      logout();
    } else {
      throw ResWaveApiException('Failed to delete account', res.statusCode);
    }
  }

  // ==================== Research Interests (Section 3.6) ====================
  Future<List<ResearchInterest>> getMyInterests() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/users/me/interests'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ResearchInterest.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to load research interests', res.statusCode);
    }
  }

  Future<ResearchInterest> addInterest(ResearchInterest interest) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/users/me/interests'),
      headers: _headers,
      body: jsonEncode(interest.toJson()),
    );
    if (res.statusCode == 200) {
      return ResearchInterest.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException(
          'Failed to save research interest', res.statusCode);
    }
  }

  Future<void> deleteInterest(String intId) async {
    final res = await http.delete(
        Uri.parse('$baseUrl/v1/users/me/interests/$intId'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException(
          'Failed to remove research interest', res.statusCode);
    }
  }

  // ==================== Domain Recommendations (Section 4) ====================
  Future<List<DomainModel>> getDomains() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/domains'));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => DomainModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to fetch taxonomy', res.statusCode);
    }
  }

  Future<List<DomainRecommendationResult>> getDomainRecommendations(
      Map<String, dynamic> questionnaire) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/domain-recommendations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(questionnaire),
    );
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => DomainRecommendationResult.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to calculate domain recommendations', res.statusCode);
    }
  }

  // ==================== Learning Hub (Section 5) ====================
  Future<List<LearningResource>> getLearningResources(
      {String? domain, String? level, String? format, String? query}) async {
    final params = <String, String>{};
    if (domain != null && domain.isNotEmpty) params['domain'] = domain;
    if (level != null && level.isNotEmpty) params['level'] = level;
    if (format != null && format.isNotEmpty) params['format'] = format;
    if (query != null && query.isNotEmpty) params['query'] = query;

    final uri = Uri.parse('$baseUrl/v1/learning/resources')
        .replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => LearningResource.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to load learning resources', res.statusCode);
    }
  }

  // ==================== Paper Library (Section 6.3) ====================
  Future<List<PaperItem>> getMyPapers() async {
    final res =
        await http.get(Uri.parse('$baseUrl/v1/papers'), headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => PaperItem.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load papers', res.statusCode);
    }
  }

  Future<PaperItem> addPaper(PaperItem paper) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/papers'),
      headers: _headers,
      body: jsonEncode(paper.toJson()),
    );
    if (res.statusCode == 200) {
      return PaperItem.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to add paper', res.statusCode);
    }
  }

  Future<void> deletePaper(String paperId) async {
    final res = await http.delete(Uri.parse('$baseUrl/v1/papers/$paperId'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to delete paper', res.statusCode);
    }
  }

  // ==================== Smart Matching (Section 7) ====================
  Future<List<dynamic>> getResearcherMatches(
      {String? domainId, String? topics, String? mode}) async {
    final params = <String, String>{};
    if (domainId != null) params['domainId'] = domainId;
    if (topics != null) params['topics'] = topics;
    if (mode != null) params['mode'] = mode;

    final uri = Uri.parse('$baseUrl/v1/matches/researchers')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException(
          'Failed to fetch researcher matches', res.statusCode);
    }
  }

  Future<List<dynamic>> getMentorMatches(
      {String? topics, String? helpType, String? level}) async {
    final params = <String, String>{};
    if (topics != null) params['topics'] = topics;
    if (helpType != null) params['helpType'] = helpType;
    if (level != null) params['level'] = level;

    final uri = Uri.parse('$baseUrl/v1/matches/mentors')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException(
          'Failed to fetch mentor matches', res.statusCode);
    }
  }

  // ==================== My Network: Connections, Followers, Following (Section 6) ====================
  Future<NetworkSummaryModel> getNetworkSummary() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/network/summary'),
        headers: _headers);
    if (res.statusCode == 200) {
      return NetworkSummaryModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException(
          'Failed to load network summary', res.statusCode);
    }
  }

  Future<List<ConnectionModel>> getConnections() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/network/connections'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ConnectionModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load connections', res.statusCode);
    }
  }

  Future<List<FollowerModel>> getFollowers() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/network/followers'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => FollowerModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load followers', res.statusCode);
    }
  }

  Future<List<FollowerModel>> getFollowing() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/network/following'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => FollowerModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load following', res.statusCode);
    }
  }

  Future<List<ConnectionRequestModel>> getSentRequests() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/network/requests/sent'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ConnectionRequestModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load sent requests', res.statusCode);
    }
  }

  Future<List<ConnectionRequestModel>> getReceivedRequests() async {
    final res = await http.get(
        Uri.parse('$baseUrl/v1/network/requests/received'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ConnectionRequestModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to load received requests', res.statusCode);
    }
  }

  Future<ConnectionRequestModel> sendConnectionRequest(String targetUid,
      {String? note}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/network/connect/$targetUid'),
      headers: _headers,
      body: jsonEncode({'note': note}),
    );
    if (res.statusCode == 200) {
      return ConnectionRequestModel.fromJson(jsonDecode(res.body));
    } else {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Failed to send request', res.statusCode);
    }
  }

  Future<void> acceptConnectionRequest(String requestId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/v1/network/connect/$requestId/accept'),
        headers: _headers);
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Failed to accept connection', res.statusCode);
    }
  }

  Future<void> declineConnectionRequest(String requestId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/v1/network/connect/$requestId/decline'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to decline connection', res.statusCode);
    }
  }

  Future<void> withdrawConnectionRequest(String requestId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/v1/network/connect/$requestId/withdraw'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to withdraw request', res.statusCode);
    }
  }

  Future<bool> toggleFollow(String targetUid) async {
    final res = await http.post(
        Uri.parse('$baseUrl/v1/network/follow/$targetUid'),
        headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['isFollowing'] ?? true;
    } else {
      throw ResWaveApiException(
          'Failed to update follow status', res.statusCode);
    }
  }

  // ==================== Mentor System (Section 8) ====================
  Future<MentorProfileModel> getMentorProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/mentor/profile'),
        headers: _headers);
    if (res.statusCode == 200) {
      return MentorProfileModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException(
          'Failed to load mentor profile', res.statusCode);
    }
  }

  Future<MentorProfileModel> updateMentorProfile(
      Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$baseUrl/v1/mentor/profile'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    if (res.statusCode == 200) {
      return MentorProfileModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException(
          'Failed to update mentor profile', res.statusCode);
    }
  }

  Future<void> sendMentorRequest({
    required String mentorId,
    required String interestId,
    required String helpType,
    required String context,
    String format = 'Remote',
    String frequency = 'Bi-weekly',
    String timezone = 'UTC',
    String? questions,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/mentor/requests'),
      headers: _headers,
      body: jsonEncode({
        'mentorId': mentorId,
        'interestId': interestId,
        'helpType': helpType,
        'context': context,
        'format': format,
        'frequency': frequency,
        'timezone': timezone,
        'questions': questions,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Failed to submit mentor request', res.statusCode);
    }
  }

  Future<List<MentorRequestModel>> getSentMentorRequests() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/mentor/requests/sent'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => MentorRequestModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to load sent mentor requests', res.statusCode);
    }
  }

  Future<List<MentorRequestModel>> getReceivedMentorRequests() async {
    final res = await http.get(
        Uri.parse('$baseUrl/v1/mentor/requests/received'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => MentorRequestModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to load received mentor requests', res.statusCode);
    }
  }

  Future<void> decideMentorRequest(String reqId, String status,
      {String? reason}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/mentor/requests/$reqId/decision'),
      headers: _headers,
      body: jsonEncode({'status': status, 'reason': reason}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Failed to update request', res.statusCode);
    }
  }

  // ==================== Academic Feed (Section 11) ====================
  Future<List<FeedPostModel>> getFeed(
      {String? domain, String? postType}) async {
    final params = <String, String>{};
    if (domain != null && domain.isNotEmpty) params['domain'] = domain;
    if (postType != null && postType.isNotEmpty) params['post_type'] = postType;

    final uri = Uri.parse('$baseUrl/v1/feed').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => FeedPostModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load academic feed', res.statusCode);
    }
  }

  Future<FeedPostModel> createFeedPost({
    required String text,
    String postType = 'Research update',
    List<String> domainTags = const [],
    String? attachmentUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/feed/posts'),
      headers: _headers,
      body: jsonEncode({
        'text': text,
        'postType': postType,
        'domainTags': domainTags,
        'attachmentUrl': attachmentUrl,
      }),
    );
    if (res.statusCode == 200) {
      return FeedPostModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to create post', res.statusCode);
    }
  }

  Future<bool> reactToPost(String postId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/v1/feed/posts/$postId/react'),
        headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['hasReacted'] ?? false;
    } else {
      throw ResWaveApiException('Failed to react to post', res.statusCode);
    }
  }

  Future<List<CommentModel>> getPostComments(String postId) async {
    final res =
        await http.get(Uri.parse('$baseUrl/v1/feed/posts/$postId/comments'));
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => CommentModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load comments', res.statusCode);
    }
  }

  Future<CommentModel> addPostComment(String postId, String text) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/feed/posts/$postId/comments'),
      headers: _headers,
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode == 200) {
      return CommentModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to post comment', res.statusCode);
    }
  }

  // ==================== Direct Messaging (Section 12) ====================
  Future<List<ConversationModel>> getConversations() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/messages/conversations'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ConversationModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load conversations', res.statusCode);
    }
  }

  Future<ConversationModel> startConversation(String targetUserId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/messages/start'),
      headers: _headers,
      body: jsonEncode({'targetUserId': targetUserId}),
    );
    if (res.statusCode == 200) {
      return ConversationModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to start conversation', res.statusCode);
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final res = await http.get(
        Uri.parse(
            '$baseUrl/v1/messages/conversations/$conversationId/messages'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => MessageModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load messages', res.statusCode);
    }
  }

  Future<MessageModel> sendMessage(String conversationId, String text) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/messages/conversations/$conversationId/messages'),
      headers: _headers,
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode == 200) {
      return MessageModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to send message', res.statusCode);
    }
  }

  // ==================== Teams, Projects & Groups (Sections 9 & 10) ====================
  Future<List<TeamRequestModel>> getTeamRequests({String? domain}) async {
    final uri = Uri.parse(
        '$baseUrl/v1/team-requests${domain != null ? '?domain=$domain' : ''}');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => TeamRequestModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load team calls', res.statusCode);
    }
  }

  Future<TeamRequestModel> createTeamRequest(
      Map<String, dynamic> requestData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/team-requests'),
      headers: _headers,
      body: jsonEncode(requestData),
    );
    if (res.statusCode == 200) {
      return TeamRequestModel.fromJson(jsonDecode(res.body));
    } else {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Failed to create team call', res.statusCode);
    }
  }

  Future<void> applyToTeam(
    String reqId, {
    String? message,
    List<String> skills = const [],
    List<String> answers = const [],
    String? resumeUrl,
    String? resumeStoragePath,
    String? resumeFileName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/team-requests/$reqId/apply'),
      headers: _headers,
      body: jsonEncode({
        if (message != null) 'message': message,
        'skills': skills,
        'answers': answers,
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        if (resumeStoragePath != null) 'resumeStoragePath': resumeStoragePath,
        if (resumeFileName != null) 'resumeFileName': resumeFileName,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Application submission failed', res.statusCode);
    }
  }

  Future<List<dynamic>> getMyTeamApplications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/v1/team-applications/me'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException(
          'Failed to load submitted applications', res.statusCode);
    }
  }

  Future<List<dynamic>> getTeamRequestApplications(String reqId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/v1/team-requests/$reqId/applications'),
        headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException('Failed to load applications', res.statusCode);
    }
  }

  Future<void> decideTeamApplication(String appId, String status) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/team-applications/$appId/decision'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Failed to update application', res.statusCode);
    }
  }

  Future<List<ProjectModel>> getMyProjects() async {
    final res =
        await http.get(Uri.parse('$baseUrl/v1/projects'), headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ProjectModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load projects', res.statusCode);
    }
  }

  Future<List<ProjectTaskModel>> getProjectTasks(String projId) async {
    final res = await http.get(Uri.parse('$baseUrl/v1/projects/$projId/tasks'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ProjectTaskModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load project tasks', res.statusCode);
    }
  }

  Future<ProjectTaskModel> addProjectTask(String projId, String title,
      {String priority = 'Medium', String? dueDate}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/projects/$projId/tasks'),
      headers: _headers,
      body: jsonEncode(
          {'title': title, 'priority': priority, 'dueDate': dueDate}),
    );
    if (res.statusCode == 200) {
      return ProjectTaskModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to add task', res.statusCode);
    }
  }

  Future<void> updateProjectTask(
      String projId, String taskId, Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$baseUrl/v1/projects/$projId/tasks/$taskId'),
      headers: _headers,
      body: jsonEncode(updates),
    );
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to update task', res.statusCode);
    }
  }

  Future<List<ProjectMilestoneModel>> getProjectMilestones(
      String projId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/v1/projects/$projId/milestones'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ProjectMilestoneModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load milestones', res.statusCode);
    }
  }

  Future<ProjectMilestoneModel> addProjectMilestone(String projId, String title,
      {String? dueDate}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/projects/$projId/milestones'),
      headers: _headers,
      body: jsonEncode({'title': title, 'dueDate': dueDate}),
    );
    if (res.statusCode == 200) {
      return ProjectMilestoneModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to add milestone', res.statusCode);
    }
  }

  Future<List<GroupModel>> getGroups({String? domain}) async {
    final uri = Uri.parse(
        '$baseUrl/v1/groups${domain != null ? '?domain=$domain' : ''}');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => GroupModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load groups', res.statusCode);
    }
  }

  Future<GroupModel> createGroup(Map<String, dynamic> groupData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/groups'),
      headers: _headers,
      body: jsonEncode(groupData),
    );
    if (res.statusCode == 200) {
      return GroupModel.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException('Failed to create group', res.statusCode);
    }
  }

  Future<void> joinGroup(String groupId) async {
    final res = await http.post(Uri.parse('$baseUrl/v1/groups/$groupId/join'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to join group', res.statusCode);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final res = await http.post(Uri.parse('$baseUrl/v1/groups/$groupId/leave'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to leave group', res.statusCode);
    }
  }

  Future<List<GroupModel>> getMyGroups() async {
    final res =
        await http.get(Uri.parse('$baseUrl/v1/groups/my'), headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => GroupModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load joined groups', res.statusCode);
    }
  }

  Future<List<dynamic>> getRecommendedGroups() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/groups/recommended'),
        headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException(
          'Failed to load group recommendations', res.statusCode);
    }
  }

  Future<List<dynamic>> getProfessionalSupport({String? query}) async {
    final uri = Uri.parse(
        '$baseUrl/v1/wellbeing/professional-support${query != null ? '?query=$query' : ''}');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException(
          'Failed to load professional resources', res.statusCode);
    }
  }

  Future<List<dynamic>> getSupportPosts() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/wellbeing/support-posts'),
        headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw ResWaveApiException(
          'Failed to load peer support posts', res.statusCode);
    }
  }

  Future<void> createSupportPost({
    required String category,
    required String text,
    bool hideIdentity = true,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/wellbeing/support-posts'),
      headers: _headers,
      body: jsonEncode({
        'category': category,
        'text': text,
        'hideIdentity': hideIdentity,
        'safetyAcknowledged': true,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw ResWaveApiException(
          err['detail'] ?? 'Failed to submit peer support post',
          res.statusCode);
    }
  }

  Future<void> withdrawMentorRequest(String reqId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/v1/mentor/requests/$reqId/withdraw'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException(
          'Failed to withdraw mentor request', res.statusCode);
    }
  }

  // ==================== Well-Being (Section 10) ====================
  Future<List<MoodEntry>> getMyMoods() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/wellbeing/moods'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => MoodEntry.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load mood entries', res.statusCode);
    }
  }

  Future<MoodEntry> saveMood(MoodEntry entry) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/wellbeing/moods'),
      headers: _headers,
      body: jsonEncode(entry.toJson()),
    );
    if (res.statusCode == 200) {
      return MoodEntry.fromJson(jsonDecode(res.body));
    } else {
      throw ResWaveApiException(
          'Failed to save mood reflection', res.statusCode);
    }
  }

  Future<void> deleteMood(String mid) async {
    final res = await http.delete(Uri.parse('$baseUrl/v1/wellbeing/moods/$mid'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException(
          'Failed to delete mood reflection', res.statusCode);
    }
  }

  Future<List<OpportunityModel>> getOpportunities(
      {String? type, String? mode}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    if (mode != null) params['mode'] = mode;

    final uri =
        Uri.parse('$baseUrl/v1/opportunities').replace(queryParameters: params);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => OpportunityModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException(
          'Failed to fetch opportunities', res.statusCode);
    }
  }

  // ==================== Notifications (Section 12 & 19) ====================
  Future<List<NotificationModel>> getNotifications() async {
    final res = await http.get(Uri.parse('$baseUrl/v1/notifications'),
        headers: _headers);
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => NotificationModel.fromJson(e)).toList();
    } else {
      throw ResWaveApiException('Failed to load notifications', res.statusCode);
    }
  }

  Future<void> markNotificationRead(String notifId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/v1/notifications/$notifId/read'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to mark read', res.statusCode);
    }
  }

  Future<void> markAllNotificationsRead() async {
    final res = await http.post(
        Uri.parse('$baseUrl/v1/notifications/mark-all-read'),
        headers: _headers);
    if (res.statusCode != 200) {
      throw ResWaveApiException('Failed to mark all read', res.statusCode);
    }
  }

  Future<void> registerFcmToken(
    String token, {
    String? deviceInfo,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/v1/notifications/fcm-token'),
      headers: _headers,
      body: jsonEncode({
        'token': token,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
      }),
    );
    if (res.statusCode != 200) {
      throw ResWaveApiException(
        'Failed to register this device for notifications',
        res.statusCode,
      );
    }
  }

  Future<void> unregisterFcmToken(String token) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/v1/notifications/fcm-token'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    if (res.statusCode != 200) {
      throw ResWaveApiException(
        'Failed to remove this device from notifications',
        res.statusCode,
      );
    }
  }
}
