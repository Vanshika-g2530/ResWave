import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'api_client.dart';
import 'push_notification_service.dart';

enum SignupFailureStage {
  firebaseAccountCreation,
  firebaseDisplayNameUpdate,
  firebaseIdToken,
  backendProfileCreation,
}

class ResWaveSignupException implements Exception {
  const ResWaveSignupException(this.stage, this.cause);

  final SignupFailureStage stage;
  final Object cause;

  @override
  String toString() =>
      'Signup failed during ${stage.name} (${cause.runtimeType}).';
}

class ResWaveAuthService {
  ResWaveAuthService._internal() {
    _firebaseAuth.idTokenChanges().listen(
      _handleAuthStateChange,
      onError: (Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace);
      },
    );
  }

  static final ResWaveAuthService instance = ResWaveAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ResWaveApiService _apiService = ResWaveApiService();

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    required String country,
    String? institution,
  }) async {
    var stage = SignupFailureStage.firebaseAccountCreation;
    try {
      final existingUser = _firebaseAuth.currentUser;
      final firebaseUser = existingUser != null &&
              existingUser.email?.toLowerCase() == email.toLowerCase()
          ? existingUser
          : (await _firebaseAuth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            ))
              .user;

      if (firebaseUser == null) {
        throw StateError('Firebase did not return a user after registration.');
      }

      stage = SignupFailureStage.firebaseDisplayNameUpdate;
      await firebaseUser.updateDisplayName(name);

      stage = SignupFailureStage.firebaseIdToken;
      final idToken = await _requireIdToken(firebaseUser);

      stage = SignupFailureStage.backendProfileCreation;
      final user = await _apiService.signupWithFirebase(
        name: name,
        email: email,
        role: role,
        country: country,
        institution: institution,
        firebaseUid: firebaseUser.uid,
        firebaseIdToken: idToken,
      );
      ResWavePushNotificationService.instance
          .registerAfterLogin(firebaseUser.uid);
      return user;
    } catch (error, stackTrace) {
      _reportSignupFailure(stage, error, stackTrace);
      Error.throwWithStackTrace(
        ResWaveSignupException(stage, error),
        stackTrace,
      );
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Firebase did not return a user after sign in.');
    }

    final idToken = await _requireIdToken(firebaseUser);
    final user = await _apiService.loginWithFirebase(
      email: email,
      firebaseUid: firebaseUser.uid,
      firebaseIdToken: idToken,
    );
    ResWavePushNotificationService.instance
        .registerAfterLogin(firebaseUser.uid);
    return user;
  }

  Future<UserModel?> restoreBackendSession() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final email = firebaseUser.email;
    if (email == null || email.isEmpty) {
      throw StateError('The signed-in Firebase account has no email address.');
    }

    final idToken = await _requireIdToken(firebaseUser);
    final user = await _apiService.loginWithFirebase(
      email: email,
      firebaseUid: firebaseUser.uid,
      firebaseIdToken: idToken,
    );
    ResWavePushNotificationService.instance
        .registerAfterLogin(firebaseUser.uid);
    return user;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      await ResWavePushNotificationService.instance
          .unregisterBeforeSignOut(firebaseUser.uid);
    }
    await _firebaseAuth.signOut();
    _apiService.logout();
  }

  Future<String> _requireIdToken(User user) async {
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Firebase did not return an ID token.');
    }
    return idToken;
  }

  void _handleAuthStateChange(User? user) {
    if (user == null) {
      _apiService.logout();
      return;
    }

    unawaited(
      _syncApiCredentials(user)
          .catchError((Object error, StackTrace stackTrace) {
        _reportError(error, stackTrace);
      }),
    );
  }

  Future<void> _syncApiCredentials(User user) async {
    final idToken = await _requireIdToken(user);
    if (_firebaseAuth.currentUser?.uid == user.uid) {
      _apiService.setFirebaseCredentials(user.uid, idToken);
    }
  }

  void _reportError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'ResWave Firebase authentication',
      ),
    );
  }

  void _reportSignupFailure(
    SignupFailureStage stage,
    Object error,
    StackTrace stackTrace,
  ) {
    final details = <String>[
      'stage=${stage.name}',
      'type=${error.runtimeType}',
      if (error is FirebaseAuthException) 'firebaseCode=${error.code}',
      if (error is ResWaveApiException && error.statusCode != null)
        'httpStatus=${error.statusCode}',
    ].join(', ');
    debugPrint('ResWave signup failed ($details).');
    debugPrintStack(stackTrace: stackTrace);
  }

  static String messageForError(
    Object error, {
    required String operation,
    bool isPasswordReset = false,
  }) {
    final signupFailure = error is ResWaveSignupException ? error : null;
    final underlyingError = signupFailure?.cause ?? error;

    if (signupFailure != null && underlyingError is ResWaveApiException) {
      if (underlyingError.message.contains('ACCOUNT_SUSPENDED') ||
          underlyingError.statusCode == 403) {
        return 'This ResWave account is suspended. Contact support for help.';
      }
      if (underlyingError.message.contains('RESWAVE_PROFILE_NOT_FOUND')) {
        return 'Firebase sign-in succeeded, but the ResWave profile could not be found.';
      }
      if (underlyingError.message.contains('FIREBASE_ID_TOKEN_INVALID') ||
          underlyingError.message.contains('FIREBASE_ID_TOKEN_REQUIRED')) {
        return 'Firebase created your account, but ResWave could not verify the sign-in. Please sign in again.';
      }
      if (underlyingError.message.contains('FIREBASE_EMAIL_MISMATCH')) {
        return 'The email entered does not match the signed-in Firebase account.';
      }
      if (underlyingError.message.contains('FIREBASE_ADMIN_NOT_CONFIGURED')) {
        return 'Firebase created your account, but ResWave authentication is temporarily unavailable. Please try again later.';
      }
      if (underlyingError.message.contains('PROFILE_STORE_UNAVAILABLE')) {
        return 'Your Firebase account exists, but ResWave could not save your profile. Retry account setup to finish creating your profile.';
      }
      if (underlyingError.statusCode == 409) {
        return 'A ResWave profile already exists for this email. Try signing in.';
      }
    }

    if (underlyingError is FirebaseAuthException) {
      switch (underlyingError.code) {
        case 'email-already-in-use':
          return 'An account already exists for this email. Try signing in.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Choose a stronger password with at least 8 characters.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return isPasswordReset
              ? 'If an account exists for this email, a password reset link will be sent.'
              : 'The email or password is incorrect.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support for help.';
        case 'too-many-requests':
          return 'Too many attempts. Wait a little and try again.';
        case 'network-request-failed':
          return 'Could not reach Firebase. Check your connection and try again.';
        case 'operation-not-allowed':
          return 'Email and password sign-in is not enabled for this Firebase project.';
        default:
          break;
      }
    }

    if (underlyingError is ResWaveApiException) {
      if (underlyingError.message.contains('ACCOUNT_SUSPENDED') ||
          underlyingError.statusCode == 403) {
        return 'This ResWave account is suspended. Contact support for help.';
      }
      if (underlyingError.message.contains('RESWAVE_PROFILE_NOT_FOUND')) {
        return 'Firebase sign-in succeeded, but the ResWave profile could not be found.';
      }
      if (underlyingError.message.contains('FIREBASE_ID_TOKEN_INVALID') ||
          underlyingError.message.contains('FIREBASE_ID_TOKEN_REQUIRED')) {
        return 'ResWave could not verify your Firebase session. Please sign in again.';
      }
      if (underlyingError.message.contains('FIREBASE_EMAIL_MISMATCH')) {
        return 'The email entered does not match the signed-in Firebase account.';
      }
      if (underlyingError.message.contains('FIREBASE_ADMIN_NOT_CONFIGURED')) {
        return 'ResWave authentication is temporarily unavailable. Please try again later.';
      }
      if (underlyingError.message.contains('PROFILE_STORE_UNAVAILABLE')) {
        return 'ResWave could not load or save your profile right now. Please try again later.';
      }
      if (underlyingError.statusCode == 409) {
        return 'A ResWave profile already exists for this email. Try signing in.';
      }
      return 'Firebase authentication succeeded, but ResWave could not complete $operation. Check your connection and try again.';
    }

    if (signupFailure != null) {
      switch (signupFailure.stage) {
        case SignupFailureStage.firebaseAccountCreation:
          return 'Could not create your Firebase account. Check your connection and try again.';
        case SignupFailureStage.firebaseDisplayNameUpdate:
          return 'Firebase created your account, but profile setup could not finish. Please retry.';
        case SignupFailureStage.firebaseIdToken:
          return 'Firebase created your account, but ResWave could not get a secure sign-in token. Please sign in again.';
        case SignupFailureStage.backendProfileCreation:
          return 'Firebase created your account, but ResWave could not save your profile. The account remains; please try again.';
      }
    }

    return 'Could not $operation. Please try again.';
  }
}
