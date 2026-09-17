import 'package:flutter_test/flutter_test.dart';
import 'package:cine_track/helpers/error_message.dart';

void main() {
  group('cleanAuthError', () {
    test('strips Exception + status prefix', () {
      expect(
        cleanAuthError('Exception: status 401: Invalid email or password'),
        'Invalid email or password',
      );
    });

    test('strips status prefix alone', () {
      expect(
        cleanAuthError('status 403: Please verify your email before logging in.'),
        'Please verify your email before logging in.',
      );
    });

    test('strips Exception prefix alone', () {
      expect(
        cleanAuthError('Exception: Unable to connect to server.'),
        'Unable to connect to server.',
      );
    });

    test('leaves clean backend message untouched', () {
      expect(
        cleanAuthError('Invalid email or password'),
        'Invalid email or password',
      );
    });

    test('fallback for empty input', () {
      expect(cleanAuthError('   '), isNotEmpty);
    });
  });

  group('isEmailNotVerifiedError (raw, before cleaning)', () {
    test('detects verify-your-email message', () {
      expect(
        isEmailNotVerifiedError(
          'Exception: status 403: Please verify your email before logging in.',
        ),
        isTrue,
      );
    });

    test('detects EMAIL_NOT_VERIFIED code', () {
      expect(
        isEmailNotVerifiedError('EMAIL_NOT_VERIFIED: verification required'),
        isTrue,
      );
    });

    test('does not flag invalid credentials', () {
      expect(
        isEmailNotVerifiedError(
          'Exception: status 401: Invalid email or password',
        ),
        isFalse,
      );
    });

    test('regression: cleaned message still maps to verify flow via raw', () {
      const raw =
          'Exception: status 403: Please verify your email before logging in.';
      // Logic branches on raw...
      expect(isEmailNotVerifiedError(raw), isTrue);
      // ...while UI shows the cleaned message.
      expect(
        cleanAuthError(raw),
        'Please verify your email before logging in.',
      );
    });
  });
}
