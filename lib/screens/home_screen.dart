import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/idle_timer_wrapper.dart';
import 'browse_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'watchlist_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkGuestRedirect();
  }

  void _checkGuestRedirect() {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest && _currentIndex >= 2 && _currentIndex <= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isGuest;

    return Scaffold(
      body: IdleTimerWrapper(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            const BrowseScreen(),
            const SearchScreen(),
            isGuest ? const _GuestGuardScreen() : const FavoritesScreen(),
            isGuest ? const _GuestGuardScreen() : const WatchlistScreen(),
            isGuest ? _buildGuestProfile() : const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (isGuest && index >= 2 && index <= 3) {
            _showGuestPrompt(context);
            return;
          }
          setState(() => _currentIndex = index);
        },
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildGuestProfile() {
    return ProfileScreen(isGuest: true, onSignIn: () {
      context.read<AuthProvider>().exitGuestMode();
    });
  }

  void _showGuestPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Sign in to use this feature',
              style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account or sign in to save favorites, build a watchlist, and track your history.',
              style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthProvider>().exitGuestMode();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sign In / Create Account',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _GuestGuardScreen extends StatelessWidget {
  const _GuestGuardScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
          const SizedBox(height: 16),
          Text(
            'Sign in to access this feature',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
