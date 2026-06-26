import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/reviews_provider.dart';
import 'providers/history_provider.dart';
import 'screens/landing_page.dart';
import 'screens/home_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/tmdb_service.dart';

class CineTrackApp extends StatelessWidget {
  const CineTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final authService = AuthService(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieProvider(TmdbService()),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(apiService, authService),
        ),
        ChangeNotifierProvider(
          create: (_) => WatchlistProvider(apiService, authService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewsProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(apiService, authService),
        ),
      ],
      child: MaterialApp(
        title: 'CineTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFC107),
            secondary: Color(0xFFFFC107),
            surface: Color(0xFF161B22),
          ),
          fontFamily: 'Inter',
        ),
        home: Consumer<AuthProvider>(
          builder: (_, auth, _) {
            if (auth.isAuthenticated) {
              if (!auth.emailVerified) {
                return const VerifyEmailScreen();
              }
              return const HomeScreen();
            }
            return const LandingPage();
          },
        ),
      ),
    );
  }
}
