import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/message_models.dart';
import '../screens/community/feed_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/messages/conversations_screen.dart';
import '../screens/network/network_screen.dart';
import '../screens/projects/projects_screen.dart';
import 'api_client.dart';

final GlobalKey<NavigatorState> resWaveNavigatorKey =
    GlobalKey<NavigatorState>();

const AndroidNotificationChannel _notificationChannel =
    AndroidNotificationChannel(
  'reswave_notifications',
  'ResWave notifications',
  description: 'Connection, message, mentorship, and project updates',
  importance: Importance.max,
);

class ResWavePushNotificationService {
  ResWavePushNotificationService._();

  static final ResWavePushNotificationService instance =
      ResWavePushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ResWaveApiService _apiService = ResWaveApiService();
  final Map<String, String> _registeredTokens = {};
  final Set<String> _handledNotificationIds = <String>{};

  Future<NotificationSettings>? _permissionRequest;
  String? _latestToken;
  String? _authenticatedUid;
  Map<String, dynamic>? _pendingTap;
  bool _initialized = false;
  bool _applicationReady = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleLocalNotificationTap(payload);
        }
      },
    );

    final androidNotifications =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.createNotificationChannel(
      _notificationChannel,
    );

    FirebaseMessaging.onMessage.listen(
      (message) => unawaited(_showForegroundNotification(message)),
      onError: (Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace, 'foreground FCM listener');
      },
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => handleNotificationTap(message.data),
      onError: (Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace, 'notification-opened listener');
      },
    );
    _messaging.onRegistered.listen(
      (token) {
        _latestToken = token;
        final uid = _authenticatedUid;
        if (uid != null) {
          unawaited(_registerTokenAndReport(uid, token));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace, 'FCM registration listener');
      },
    );

    final localLaunch =
        await _localNotifications.getNotificationAppLaunchDetails();
    final localPayload = localLaunch?.notificationResponse?.payload;
    if (localLaunch?.didNotificationLaunchApp == true &&
        localPayload != null &&
        localPayload.isNotEmpty) {
      _handleLocalNotificationTap(localPayload);
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationTap(initialMessage.data);
    }
    _initialized = true;
  }

  void registerAfterLogin(String uid) {
    _authenticatedUid = uid;
    unawaited(_requestPermissionAndRegister(uid));
  }

  Future<void> unregisterBeforeSignOut(String uid) async {
    try {
      final token = _registeredTokens[uid] ?? _latestToken;
      if (token != null && token.isNotEmpty) {
        await _apiService.unregisterFcmToken(token);
      }
      _registeredTokens.remove(uid);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'removing the signed-out device token');
    } finally {
      if (_authenticatedUid == uid) {
        _authenticatedUid = null;
        _applicationReady = false;
      }
    }
  }

  void markApplicationReady() {
    _applicationReady = true;
    final pendingTap = _pendingTap;
    if (pendingTap != null) {
      _pendingTap = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationTap(pendingTap);
      });
    }
  }

  void handleNotificationTap(Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data);
    if (!_canNavigate) {
      _pendingTap = payload;
      return;
    }
    unawaited(_navigateFromNotification(payload));
  }

  Future<void> _requestPermissionAndRegister(String uid) async {
    try {
      final permission = _permissionRequest ??= _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final settings = await permission;
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('ResWave notification permission is denied on this device.');
      }

      await _messaging.register();
      final token = _latestToken;
      if (token != null && token.isNotEmpty) {
        await _registerToken(uid, token);
      }
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'requesting permission/registering FCM');
    }
  }

  Future<void> _registerTokenAndReport(String uid, String token) async {
    try {
      await _registerToken(uid, token);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'registering a refreshed FCM token');
    }
  }

  Future<void> _registerToken(String uid, String token) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (_authenticatedUid != uid ||
        firebaseUser?.uid != uid ||
        _apiService.currentUser?.uid != uid) {
      return;
    }

    final idToken = await firebaseUser!.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
          'Firebase did not return an ID token for FCM registration.');
    }
    _apiService.setFirebaseCredentials(uid, idToken);

    final previousToken = _registeredTokens[uid];
    if (previousToken == token) return;

    await _apiService.registerFcmToken(
      token,
      deviceInfo: defaultTargetPlatform.name,
    );
    _registeredTokens[uid] = token;

    if (previousToken != null && previousToken != token) {
      try {
        await _apiService.unregisterFcmToken(previousToken);
      } catch (error, stackTrace) {
        _reportError(error, stackTrace, 'removing a superseded FCM token');
      }
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notifId = message.data['notificationId']?.toString() ?? message.messageId;
    if (notifId != null && notifId.isNotEmpty) {
      if (_handledNotificationIds.contains(notifId)) {
        return; // Suppress duplicate notification
      }
      _handledNotificationIds.add(notifId);
      if (_handledNotificationIds.length > 200) {
        _handledNotificationIds.remove(_handledNotificationIds.first);
      }
    }

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final payload = <String, dynamic>{
      ...message.data,
      if (title != null) '_displayTitle': title,
      if (body != null) '_displayBody': body,
    };
    try {
      await _localNotifications.show(
        id: (message.messageId ??
                    DateTime.now().microsecondsSinceEpoch.toString())
                .hashCode &
            0x7fffffff,
        title: title ?? 'ResWave',
        body: body ?? '',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'reswave_notifications',
            'ResWave notifications',
            channelDescription:
                'Connection, message, mentorship, and project updates',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(payload),
      );
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'showing a foreground notification');
    }
  }

  void _handleLocalNotificationTap(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        handleNotificationTap(decoded);
      } else {
        throw const FormatException(
            'Notification payload must be a JSON object.');
      }
    } on FormatException catch (error, stackTrace) {
      _reportError(error, stackTrace, 'decoding a local notification tap');
    }
  }

  Future<void> _navigateFromNotification(
    Map<String, dynamic> data,
  ) async {
    final navigator = resWaveNavigatorKey.currentState;
    if (navigator == null) {
      _pendingTap = data;
      return;
    }

    final notificationId = data['notificationId']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      try {
        await _apiService.markNotificationRead(notificationId);
      } catch (error, stackTrace) {
        _reportError(error, stackTrace, 'marking a push notification as read');
      }
    }

    final targetType = data['targetType']?.toString().toLowerCase();
    final targetId = data['targetId']?.toString();
    switch (targetType) {
      case 'conversation':
        await _openConversation(navigator, targetId);
        return;
      case 'connectionrequest':
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const NetworkScreen(initialTabIndex: 1),
          ),
        );
        return;
      case 'user':
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const NetworkScreen()),
        );
        return;
      case 'mentorrequest':
      case 'mentorship':
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const DiscoverScreen(initialTabIndex: 1),
          ),
        );
        return;
      case 'teamapplication':
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const ProjectsScreen(initialTabIndex: 0),
          ),
        );
        return;
      case 'project':
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const ProjectsScreen(initialTabIndex: 1),
          ),
        );
        return;
      case 'group':
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const ProjectsScreen(initialTabIndex: 2),
          ),
        );
        return;
      case 'post':
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const FeedScreen()),
        );
        return;
      default:
        _reportError(
          StateError('No ResWave destination is defined for "$targetType".'),
          StackTrace.current,
          'routing a notification tap',
        );
    }
  }

  Future<void> _openConversation(
    NavigatorState navigator,
    String? conversationId,
  ) async {
    if (conversationId == null || conversationId.isEmpty) {
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const ConversationsScreen(),
        ),
      );
      return;
    }

    try {
      final conversations = await _apiService.getConversations();
      ConversationModel? conversation;
      for (final item in conversations) {
        if (item.id == conversationId) {
          conversation = item;
          break;
        }
      }
      if (conversation == null) {
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const ConversationsScreen(),
          ),
        );
        return;
      }
      final matchedConversation = conversation;
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            conversationTitle: matchedConversation.otherUserName,
            participantRole: matchedConversation.otherUserRole ?? 'Researcher',
            conversationId: matchedConversation.id,
          ),
        ),
      );
    } catch (error, stackTrace) {
      _reportError(
          error, stackTrace, 'opening a conversation from a notification');
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const ConversationsScreen(),
        ),
      );
    }
  }

  bool get _canNavigate {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    return _applicationReady &&
        firebaseUid != null &&
        firebaseUid == _authenticatedUid &&
        _apiService.currentUser?.uid == firebaseUid;
  }

  void _reportError(Object error, StackTrace stackTrace, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'ResWave push notifications',
        context: ErrorDescription(context),
      ),
    );
  }
}
