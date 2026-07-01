import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded(() {
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
    runApp(const CineTrackApp());
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
