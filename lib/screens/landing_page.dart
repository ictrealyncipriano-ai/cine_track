import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/responsive.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _features = [
    _FeatureData(Icons.search_rounded, 'Smart Search',
        'Find any movie instantly with powerful search'),
    _FeatureData(Icons.cloud_sync_rounded, 'API-Powered Discovery',
        'Browse trending and top-rated movies live from TMDB'),
    _FeatureData(Icons.favorite_rounded, 'Favorites & Watchlist',
        'Save movies to your favorites or build a watchlist'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesk = Responsive.isDesktop(context);
    final padding = Responsive.horizontalPadding(context);
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0D1117), const Color(0xFF1a0a2e), const Color(0xFF0D1117)]
                : [const Color(0xFFF5F3F0), const Color(0xFFE8E0F0), const Color(0xFFF5F3F0)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _Logo(isDesk: isDesk),
                        const SizedBox(height: 16),
                        Text(
                          'CineTrack',
                          style: GoogleFonts.montserrat(
                            fontSize: Responsive.font(context, 40),
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your personal cinema command center',
                          style: GoogleFonts.inter(
                            fontSize: isDesk ? 22 : 18,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track every film. Discover your next obsession.',
                          style: GoogleFonts.inter(
                            fontSize: isDesk ? 16 : 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),
                        if (isDesk)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _features
                                .map((f) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: _FeatureCard(
                                          icon: f.icon,
                                          title: f.title,
                                          description: f.description,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          )
                        else
                          Column(
                            children: _features
                                .map((f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _FeatureCard(
                                        icon: f.icon,
                                        title: f.title,
                                        description: f.description,
                                      ),
                                    ))
                                .toList(),
                          ),
                        const SizedBox(height: 48),
                        if (isDesk)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SignInButton(),
                              const SizedBox(width: 16),
                              _CreateAccountButton(),
                            ],
                          )
                        else ...[
                          _SignInButton(),
                          const SizedBox(height: 16),
                          _CreateAccountButton(),
                        ],
                        const SizedBox(height: 24),
                        _GuestButton(),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Guest mode: browse and search only. Sign in to save favorites, build watchlists, and track history.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          htmlFooter,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: padding,
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () => theme.toggle(),
                  tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const htmlFooter = '\u00a9 2026 CineTrack. Powered by TMDB.';

// ── Logo widget ──────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final bool isDesk;
  const _Logo({required this.isDesk});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: isDesk ? 120 : 100,
      height: isDesk ? 120 : 100,
      errorBuilder: (_, __, ___) => CircleAvatar(
        radius: isDesk ? 60 : 50,
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        child: Text(
          'CT',
          style: GoogleFonts.montserrat(
            fontSize: isDesk ? 40 : 32,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ── Feature card ─────────────────────────────────────────────────

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureData(this.icon, this.title, this.description);
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buttons ──────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        child: Text(
          'Sign In',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 260,
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : const Color(0xFF2C2C2C),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          'Create Account',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _GuestButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.read<AuthProvider>().enterGuestMode();
        },
        icon: const Icon(Icons.explore_outlined, size: 20),
        label: Text(
          'Continue as Guest',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
