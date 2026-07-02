import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool onboardingDone = false;
  try {
    final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
    onboardingDone = prefs.getBool('onboarding_completed') ?? false;
  } catch (e) {
    debugPrint('SharedPreferences init error: $e');
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xFF0D1117),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong. Please restart the app.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runZonedGuarded(() {
    runApp(CineTrackApp(onboardingDone: onboardingDone));
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
