import 'dart:convert';
import 'package:flutter/material.dart';
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
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_reviews_screen.dart';

/// Creates the [GoRouter] instance for web.
/// Detail screens (movie, stream, see-all, etc.) still use Navigator.push
/// to avoid complex parameter passing and keep mobile compatibility.
GoRouter createAppRouter({Listenable? refreshListenable}) {
  return GoRouter(
    initialLocation: '/browse',
    refreshListenable: refreshListenable,
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

      // Admin guard
      if (path.startsWith('/admin') && auth.user?.isAdmin != true) {
        return '/browse';
      }

      return null;
    },
    routes: [
      // â”€â”€ Standalone routes â”€â”€
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => OnboardingScreen(
          onComplete: () {
            SharedPreferences.getInstance().then((prefs) {
              prefs.setBool('onboarding_completed', true);
            });
          },
        ),
      ),
      GoRoute(
        path: '/landing',
        builder: (_, _) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (_, _) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (_, _) => const ForgotPasswordScreen(),
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
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/verification-sent',
        builder: (_, state) => VerificationSentScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),

      // â”€â”€ Shell route (auth screens with responsive nav) â”€â”€
      ShellRoute(
        builder: (context, state, child) {
          return _WebShell(child: child);
        },
        routes: [
          GoRoute(path: '/browse', builder: (_, _) => const BrowseScreen()),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
          GoRoute(path: '/watchlist', builder: (_, _) => const WatchlistScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          // Admin routes (inside shell, keeps nav visible)
          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
          GoRoute(path: '/admin/reviews', builder: (_, __) => const AdminReviewsScreen()),
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
    final items = _navItems(isAdmin);
    final idx = items.indexWhere((item) => path.startsWith(item.route));
    return idx >= 0 ? idx : 0;
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




