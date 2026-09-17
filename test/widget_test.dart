import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_track/l10n/app_localizations.dart';
import 'package:cine_track/providers/theme_provider.dart';
import 'package:cine_track/screens/landing_page.dart';

void main() {
  testWidgets('Landing page displays app title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LandingPage(),
        ),
      ),
    );

    expect(find.text('CineTrack'), findsOneWidget);
    expect(find.text('Your personal cinema command center'), findsOneWidget);
    expect(find.text('Track every film. Discover your next obsession.'), findsOneWidget);
  });
}
