import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../widgets/idle_timer_wrapper.dart';
import '../widgets/profile_drawer.dart';
import 'browse_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'watchlist_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkGuestRedirect();
  }

  void _checkGuestRedirect() {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest && _currentIndex >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 0);
      });
    }
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.isGuest;

    return Scaffold(
      key: _scaffoldKey,
      drawer: ProfileDrawer(),
      body: Stack(
        children: [
          IdleTimerWrapper(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const BrowseScreen(),
                const SearchScreen(),
                isGuest ? const _GuestGuardScreen() : const FavoritesScreen(),
                isGuest ? const _GuestGuardScreen() : const WatchlistScreen(),
                isGuest ? const _GuestGuardScreen() : const HistoryScreen(),
              ],
            ),
          ),
          _buildProfileButton(auth),
        ],
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
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.white38,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton(AuthProvider auth) {
    final user = auth.user;
    final isGuest = auth.isGuest && !auth.isAuthenticated;

    return Positioned(
      top: 12,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openDrawer,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: ClipOval(
              child: isGuest || user == null
                  ? Icon(Icons.person_outline, size: 22, color: Colors.white70)
                  : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? (user.avatarUrl!.startsWith('data:')
                          ? Image.memory(base64Decode(user.avatarUrl!.split(',')[1]), fit: BoxFit.cover)
                          : CachedNetworkImage(imageUrl: user.avatarUrl!, fit: BoxFit.cover, placeholder: (_, __) => const Icon(Icons.person, size: 22, color: Colors.white54), errorWidget: (_, __, ___) => const Icon(Icons.person, size: 22, color: Colors.white54)))
                      : const Icon(Icons.person, size: 22, color: Colors.white70)),
            ),
          ),
        ),
      ),
    );
  }

  void _showGuestPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.lock_outline, size: 48, color: Color(0xFFFFC107)),
            const SizedBox(height: 16),
            Text(
              'Sign in to use this feature',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account or sign in to save favorites, build a watchlist, and track your history.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthProvider>().exitGuestMode();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Sign in to access this feature',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
