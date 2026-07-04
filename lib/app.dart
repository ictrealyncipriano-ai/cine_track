import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/reviews_provider.dart';
import 'providers/history_provider.dart';
import 'providers/theme_provider.dart';
import 'theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/landing_page.dart';
import 'screens/home_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/tmdb_service.dart';

class CineTrackApp extends StatefulWidget {
  final bool onboardingDone;

  const CineTrackApp({super.key, required this.onboardingDone});

  @override
  State<CineTrackApp> createState() => _CineTrackAppState();
}

class _CineTrackAppState extends State<CineTrackApp> {
  late bool _onboardingDone;

  @override
  void initState() {
    super.initState();
    _onboardingDone = widget.onboardingDone;
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      setState(() => _onboardingDone = true);
    }
  }

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
          create: (_) => ThemeProvider(),
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
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          return MaterialApp(
            title: 'CineTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: !_onboardingDone
                ? OnboardingScreen(onComplete: _completeOnboarding)
                : Consumer<AuthProvider>(
              builder: (_, auth, __) {
                if (auth.isLoading) {
                  return const _SplashScreen();
                }
                if (auth.isAuthenticated || auth.isGuest) {
                  if (auth.isAuthenticated && !auth.emailVerified) {
                    return const VerifyEmailScreen();
                  }
                  return const HomeScreen();
                }
                return const LandingPage();
              },
            ),
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
