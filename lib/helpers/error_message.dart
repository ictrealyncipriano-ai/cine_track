/// Display-only sanitizer for auth/API errors.
///
/// AuthService preserves the raw/backend-meaningful error string so screens
/// can branch on machine-detectable conditions (e.g. `EMAIL_NOT_VERIFIED`
/// or "verify your email"). Call this only when rendering / showing a
/// SnackBar so users see a clean message.
String cleanAuthError(String raw) {
  var message = raw.trim();
  if (message.isEmpty) return 'Something went wrong. Please try again.';

  // Strip Dart Exception wrapper(s): "Exception: ..." (repeat-safe).
  final exceptionPrefix = RegExp(r'^(Exception|Error)\s*:\s*', caseSensitive: false);
  while (exceptionPrefix.hasMatch(message)) {
    message = message.replaceFirst(exceptionPrefix, '').trim();
  }

  // Strip HTTP status prefix(es): "status 401: ..." (repeat-safe).
  final statusPrefix = RegExp(r'^status\s+\d+\s*:\s*', caseSensitive: false);
  while (statusPrefix.hasMatch(message)) {
    message = message.replaceFirst(statusPrefix, '').trim();
  }

  if (message.isEmpty) return 'Something went wrong. Please try again.';
  return message;
}

/// Returns true if the *raw* (unsanitized) auth error indicates the email
/// is not verified. Check this on the raw error BEFORE cleaning, so the
/// machine-readable identifier is never lost by display sanitizing.
bool isEmailNotVerifiedError(String rawError) {
  final lower = rawError.toLowerCase();
  return lower.contains('verify your email') ||
      rawError.contains('EMAIL_NOT_VERIFIED');
}
