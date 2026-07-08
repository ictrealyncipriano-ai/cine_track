# Admin Flutter Side Integration Plan

Two files need edits: `lib/app.dart` and `lib/router/app_router.dart`
After editing: `flutter build web --release --no-tree-shake-icons`, then `flutter build apk --release --no-tree-shake-icons --android-skip-build-dependency-validation`, then `git add -A && git commit -m "Wire admin screens into app + router" && git push origin main`

---

## 1. `lib/app.dart` — Full Replacement

Replace the entire file with:

```dart
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
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

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
        ChangeNotifierProvider(
          create: (_) => AdminProvider(apiService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          if (kIsWeb) {
            _router ??= createAppRouter();
            return MaterialApp.router(
              title: 'CineTrack',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeProvider.themeMode,
              routerConfig: _router!,
            );
          }

          return MaterialApp(
            title: 'CineTrack',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
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
```

---

## 2. `lib/router/app_router.dart` — Changes

### a. Add imports after line 21

```dart
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_reviews_screen.dart';
```

### b. Add admin guard in `redirect` (after email verification, before `return null`)

```dart
      // Admin guard
      if (path.startsWith('/admin') && auth.user?.isAdmin != true) {
        return '/browse';
      }
```

### c. Add admin routes inside ShellRoute (after /profile line, before closing bracket)

```dart
          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
          GoRoute(path: '/admin/reviews', builder: (_, __) => const AdminReviewsScreen()),
```

### d. Replace the entire `_WebShellState` class (lines 131-256) with:

```dart
class _WebShellState extends State<_WebShell> {
  List<_NavItem> _navItems(bool isAdmin) => [
        _NavItem('Browse', Icons.explore_outlined, Icons.explore, '/browse'),
        _NavItem('Search', Icons.search_outlined, Icons.search, '/search'),
        _NavItem('Favorites', Icons.favorite_outline, Icons.favorite, '/favorites'),
        _NavItem('Watchlist', Icons.bookmark_outline, Icons.bookmark, '/watchlist'),
        if (isAdmin)
          _NavItem('Admin', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, '/admin'),
        _NavItem('Profile', Icons.person_outline, Icons.person, '/profile'),
      ];

  int _currentTabForPath(String path, bool isAdmin) {
    if (path.startsWith('/browse')) return 0;
    if (path.startsWith('/search')) return 1;
    if (path.startsWith('/favorites')) return 2;
    if (path.startsWith('/watchlist')) return 3;
    if (isAdmin && path.startsWith('/admin')) return 4;
    if (path.startsWith('/profile')) return isAdmin ? 5 : 4;
    return 0;
  }

  void _onTabSelected(int index) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.user?.isAdmin ?? false;
    final items = _navItems(isAdmin);
    if (index >= 0 && index < items.length) {
      context.go(items[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isDesktop(context);
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.user?.isAdmin ?? false;
    final currentPath = GoRouterState.of(context).matchedLocation;
    final items = _navItems(isAdmin);
    final currentIndex = _currentTabForPath(currentPath, isAdmin);

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: _onTabSelected,
              labelType: NavigationRailLabelType.all,
              minWidth: 72,
              leading: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Icon(
                    Icons.movie_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CineTrack',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                ],
              ),
              trailing: auth.isAuthenticated
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: auth.user?.avatarUrl != null &&
                                auth.user!.avatarUrl!.isNotEmpty
                            ? (auth.user!.avatarUrl!.startsWith('data:')
                                ? MemoryImage(
                                    base64Decode(
                                      auth.user!.avatarUrl!.split(',').length >= 2
                                          ? auth.user!.avatarUrl!.split(',')[1]
                                          : '',
                                    ),
                                  )
                                : NetworkImage(auth.user!.avatarUrl!) as ImageProvider)
                            : null,
                        child: auth.user?.avatarUrl == null ||
                                auth.user!.avatarUrl!.isEmpty
                            ? Icon(Icons.person, size: 20)
                            : null,
                      ),
                    )
                  : const SizedBox.shrink(),
              destinations: List.generate(items.length, (i) {
                return NavigationRailDestination(
                  icon: Icon(items[i].icon),
                  selectedIcon: Icon(items[i].activeIcon),
                  label: Text(items[i].label, style: GoogleFonts.inter(fontSize: 12)),
                );
              }),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: currentIndex >= 0 && currentIndex < items.length ? currentIndex : 0,
              onTap: _onTabSelected,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.54),
              items: List.generate(items.length, (i) {
                return BottomNavigationBarItem(
                  icon: Icon(items[i].icon),
                  activeIcon: Icon(items[i].activeIcon),
                  label: items[i].label,
                );
              }),
            ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItem(this.label, this.icon, this.activeIcon, this.route);
}
```

---

## 3. Build Commands

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
flutter build web --release --no-tree-shake-icons
flutter build apk --release --no-tree-shake-icons --android-skip-build-dependency-validation
```

## 4. Git Push

```powershell
git add -A
git commit -m "Wire admin screens into app + router"
git push origin main
```

Vercel will auto-deploy from the push.
