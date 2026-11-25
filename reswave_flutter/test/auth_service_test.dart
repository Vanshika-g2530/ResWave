import 'package:flutter_test/flutter_test.dart';
import 'package:reswave/services/api_client.dart';
import 'package:reswave/services/auth_service.dart';

void main() {
  test('signup explains when profile persistence is unavailable', () {
    final error = ResWaveSignupException(
      SignupFailureStage.backendProfileCreation,
      ResWaveApiException('PROFILE_STORE_UNAVAILABLE', 503),
    );

    final message = ResWaveAuthService.messageForError(
      error,
      operation: 'create your account',
    );

    expect(message, contains('Your Firebase account exists'));
    expect(message, contains('could not save your profile'));
    expect(message, contains('Retry account setup'));
    expect(message, isNot(contains('PROFILE_STORE_UNAVAILABLE')));
  });
}
