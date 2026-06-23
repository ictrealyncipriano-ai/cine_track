import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cine_track/screens/landing_page.dart';

void main() {
  testWidgets('Landing page displays app title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: const LandingPage()),
    );

    expect(find.text('CineTrack'), findsOneWidget);
    expect(find.text('Discover. Track. Watch.'), findsOneWidget);
    expect(find.text('Smart Search'), findsOneWidget);
    expect(find.text('API-Powered Discovery'), findsOneWidget);
    expect(find.text('Favorites & Watchlist'), findsOneWidget);
    expect(find.text('Explore Movies'), findsOneWidget);
  });
}
