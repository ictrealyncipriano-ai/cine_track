import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cine_track/helpers/error_message.dart';
import 'package:cine_track/widgets/auth_error_banner.dart';

void main() {
  testWidgets('AuthErrorBanner shows cleaned message with error icon',
      (tester) async {
    const raw = 'Exception: status 401: Invalid email or password';
    final cleaned = cleanAuthError(raw);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthErrorBanner(message: 'Invalid email or password'),
        ),
      ),
    );

    // Observable UI: cleaned text visible, raw prefixes gone.
    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(find.textContaining('Exception:'), findsNothing);
    expect(find.textContaining('status 401'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(cleaned, 'Invalid email or password');
  });

  testWidgets('showAuthErrorSnackBar deduplicates via hideCurrentSnackBar',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAuthErrorSnackBar(context, 'First failure');
                showAuthErrorSnackBar(context, 'Second failure');
              },
              child: const Text('Fail'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Fail'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Only the latest message should be visible (no stacking).
    expect(find.text('Second failure'), findsOneWidget);
    expect(find.text('First failure'), findsNothing);
  });
}
