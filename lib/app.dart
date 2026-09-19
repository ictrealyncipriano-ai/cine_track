import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/reviews_provider.dart';
import 'providers/history_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/home_content_provider.dart';
import 'providers/review_reply_provider.dart';
import 'providers/admin/activity_log_provider.dart';
import 'providers/admin/admin_settings_provider.dart';
import 'providers/admin/analytics_provider.dart';
import 'providers/admin/banner_management_provider.dart';
import 'providers/admin/movie_management_provider.dart';
import 'providers/admin/review_moderation_provider.dart';
import 'providers/admin/user_management_provider.dart';
import 'router/app_router.dart';
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
  GoRouter? _router;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _onboardingDone = widget.onboardingDone;
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
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
    if (!_onboardingDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: OnboardingScreen(onComplete: _completeOnboarding),
      );
    }

    final apiService = ApiService();
    final authService = AuthService(apiService);

    return MultiProvider(
      providers: [
Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => MovieProvider(TmdbService())),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(apiService, authService)),
        ChangeNotifierProvider(create: (_) => WatchlistProvider(apiService, authService)),
        ChangeNotifierProvider(create: (_) => ReviewsProvider(apiService)),
        ChangeNotifierProvider(create: (_) => HistoryProvider(apiService, authService)),
        ChangeNotifierProvider(create: (_) => AdminProvider(apiService)),
        ChangeNotifierProvider(create: (_) => HomeContentProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ReviewReplyProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ActivityLogProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AdminSettingsProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider(apiService)),
        ChangeNotifierProvider(create: (_) => BannerManagementProvider(apiService)),
        ChangeNotifierProvider(create: (_) => MovieManagementProvider(apiService)),
        ChangeNotifierProvider(create: (_) => ReviewModerationProvider(apiService)),
        ChangeNotifierProvider(create: (_) => UserManagementProvider(apiService)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (innerCtx, themeProvider, _) {
          if (kIsWeb) {
            final auth = innerCtx.read<AuthProvider>();
            _router ??= createAppRouter(auth);
            return MaterialApp.router(
              title: 'CineTrack',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeProvider.themeMode,
              routerConfig: _router!,
              scaffoldMessengerKey: _scaffoldMessengerKey,
            );
          }

          return MaterialApp(
            title: 'CineTrack',
            debugShowCheckedModeBanner: false,
theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (_, auth, _) {
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
      body: SafeArea(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}


