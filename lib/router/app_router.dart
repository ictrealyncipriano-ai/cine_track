import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/responsive.dart';
import '../providers/auth_provider.dart';
import '../screens/onboarding_screen.dart';
import '../screens/landing_page.dart';
import '../screens/browse_screen.dart';
import '../screens/search_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/watchlist_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/verification_sent_screen.dart';
import '../widgets/responsive_shell.dart';

/// Creates the [GoRouter] instance for web.
/// Detail screens (movie, stream, see-all, etc.) still use Navigator.push
/// to avoid complex parameter passing and keep mobile compatibility.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/browse',
    redirect: (context, state) async {
      final auth = context.read<AuthProvider>();
      final isAuth = auth.isAuthenticated || auth.isGuest;
      final path = state.matchedLocation;

      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_completed') ?? false;

      final isAuthRoute = path.startsWith('/login') ||
          path.startsWith('/register') ||
          path.startsWith('/forgot-password') ||
          path.startsWith('/reset-password') ||
          path == '/landing';

      // Onboarding guard
      if (!onboardingDone && path != '/onboarding') return '/onboarding';
      if (onboardingDone && path == '/onboarding') return '/browse';

      // Auth guard
      if (!isAuth && !isAuthRoute) return '/landing';
      if (isAuth && isAuthRoute) return '/browse';

      // Email verification guard
      if (isAuth && auth.isAuthenticated && !auth.emailVerified && path != '/verify-email') {
        return '/verify-email';
      }

      return null;
    },
    routes: [
      // ── Standalone routes ──
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => OnboardingScreen(
          onComplete: () {
            SharedPreferences.getInstance().then((prefs) {
              prefs.setBool('onboarding_completed', true);
            });
          },
        ),
      ),
      GoRoute(
        path: '/landing',
        builder: (_, __) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (_, __) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (_, __) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'reset-password',
            builder: (_, state) {
              final email = state.uri.queryParameters['email'] ?? '';
              final token = state.uri.queryParameters['token'] ?? '';
              return ResetPasswordScreen(email: email, token: token);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/verification-sent',
        builder: (_, __) => const VerificationSentScreen(email: ''),
      ),

      // ── Shell route (auth screens with responsive nav) ──
      ShellRoute(
        builder: (context, state, child) {
          return _WebShell(child: child);
        },
        routes: [
          GoRoute(path: '/browse', builder: (_, __) => const BrowseScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
          GoRoute(path: '/watchlist', builder: (_, __) => const WatchlistScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
}

/// Web-specific shell with responsive NavigationRail / BottomNavigationBar.
class _WebShell extends StatefulWidget {
  final Widget child;
  const _WebShell({required this.child});

  @override
  State<_WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<_WebShell> {
  static const _navLabels = ['Browse', 'Search', 'Favorites', 'Watchlist', 'Profile'];
  static const _navIcons = [
    Icons.explore_outlined,
    Icons.search_outlined,
    Icons.favorite_outline,
    Icons.bookmark_outline,
    Icons.person_outline,
  ];
  static const _navSelectedIcons = [
    Icons.explore,
    Icons.search,
    Icons.favorite,
    Icons.bookmark,
    Icons.person,
  ];

  int _currentTabForPath(String path) {
    if (path.startsWith('/browse')) return 0;
    if (path.startsWith('/search')) return 1;
    if (path.startsWith('/favorites')) return 2;
    if (path.startsWith('/watchlist')) return 3;
    if (path.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTabSelected(int index) {
    final routes = ['/browse', '/search', '/favorites', '/watchlist', '/profile'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isDesktop(context);
    final auth = context.watch<AuthProvider>();
    final currentPath = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentTabForPath(currentPath);

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
              destinations: List.generate(_navLabels.length, (i) {
                return NavigationRailDestination(
                  icon: Icon(_navIcons[i]),
                  selectedIcon: Icon(_navSelectedIcons[i]),
                  label: Text(_navLabels[i], style: GoogleFonts.inter(fontSize: 12)),
                );
              }),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: _onTabSelected,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.54),
              items: List.generate(_navLabels.length, (i) {
                return BottomNavigationBarItem(
                  icon: Icon(_navIcons[i]),
                  activeIcon: Icon(_navSelectedIcons[i]),
                  label: _navLabels[i],
                );
              }),
            ),
    );
  }
}
