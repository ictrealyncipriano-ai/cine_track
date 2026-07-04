import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_completed') ?? false;

  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}');
    };
    ErrorWidget.builder = (details) {
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: Color(0xFF0D1117),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Something went wrong. Please restart the app.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    };
    runApp(CineTrackApp(onboardingDone: onboardingDone));
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
