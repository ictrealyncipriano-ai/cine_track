import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/watchlist_provider.dart';
import '../providers/history_provider.dart';
import 'avatar_picker.dart';
import '../screens/sessions_screen.dart';
import '../screens/my_reviews_screen.dart';
import '../screens/landing_page.dart';

class ProfileDrawer extends StatefulWidget {
  final VoidCallback? onEditProfile;
  final VoidCallback? onScrollToPassword;

  const ProfileDrawer({super.key, this.onEditProfile, this.onScrollToPassword});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    } catch (_) {}
  }

  void _pickAvatar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarPicker(
        onPicked: (base64, mime) {
          if (base64.isEmpty) {
            // TODO: implement avatar removal via API if needed
            return;
          }
          context.read<AuthProvider>().uploadAvatar(base64, mime).then((error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Avatar updated'),
                  backgroundColor: error != null ? Colors.redAccent : Colors.green,
                ),
              );
            }
          });
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showCacheCleared(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
        content: Text(
          'Clear cached images and data?',
          style: GoogleFonts.inter(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CachedNetworkImage.evictFromCache('*');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langOption(ctx, 'English', true),
            _langOption(ctx, 'Spanish', false),
            _langOption(ctx, 'French', false),
            _langOption(ctx, 'German', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _langOption(BuildContext ctx, String name, bool selected) {
    return ListTile(
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? const Color(0xFFFFC107) : Colors.white38),
      title: Text(name, style: GoogleFonts.inter(color: selected ? Colors.white : Colors.white54)),
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Language switching coming soon'), backgroundColor: Colors.orangeAccent),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/logo.png', height: 64),
            ),
            const SizedBox(height: 16),
            Text('CineTrack', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('v$_appVersion', style: GoogleFonts.inter(color: Colors.white54)),
            const SizedBox(height: 16),
            Text(
              'Track your movies, build watchlists, and discover new favorites.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isGuest && !auth.isAuthenticated) {
      return _buildGuestDrawer(context, auth);
    }

    return _buildAuthDrawer(context, auth);
  }

  Widget _buildAuthDrawer(BuildContext context, AuthProvider auth) {
    final user = auth.user;
    final theme = context.watch<ThemeProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final watchlistProvider = context.watch<WatchlistProvider>();
    final historyProvider = context.watch<HistoryProvider>();

    return Drawer(
      backgroundColor: const Color(0xFF0D1117),
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _pickAvatar(context),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                ? (user.avatarUrl!.startsWith('data:')
                                    ? MemoryImage(base64Decode(user.avatarUrl!.split(',')[1]))
                                    : CachedNetworkImageProvider(user.avatarUrl!))
                                : null,
                            child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                                ? Icon(Icons.person, size: 32, color: Theme.of(context).colorScheme.primary)
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0D1117), width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 12, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'User',
                            style: GoogleFonts.montserrat(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user?.username ?? ''}',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _sectionHeader('My Activity'),
              _drawerItem(
                icon: Icons.bar_chart_rounded,
                label: 'Statistics',
                trailing: Text(
                  '${favoritesProvider.favorites.length} · ${watchlistProvider.watchlist.length} · ${historyProvider.history.length}',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _drawerItem(
                icon: Icons.rate_review_outlined,
                label: 'My Reviews',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
                },
              ),
              const Divider(color: Colors.white12, height: 24),
              _sectionHeader('Settings'),
              _drawerItem(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEditProfile?.call();
                },
              ),
              _drawerItem(
                icon: Icons.lock_outline,
                label: 'Change Password',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                onTap: () {
                  Navigator.pop(context);
                  widget.onScrollToPassword?.call();
                },
              ),
              _drawerItem(
                icon: theme.isDark ? Icons.light_mode : Icons.dark_mode,
                label: theme.isDark ? 'Light Mode' : 'Dark Mode',
                trailing: Switch(
                  value: !theme.isDark,
                  activeTrackColor: const Color(0xFFFFC107),
                  activeThumbColor: Colors.black,
                  inactiveTrackColor: Colors.white24,
                  inactiveThumbColor: Colors.white54,
                  onChanged: (_) => theme.toggle(),
                ),
                onTap: () => theme.toggle(),
              ),
              _drawerItem(
                icon: Icons.language,
                label: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('English', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageDialog(context);
                },
              ),
              _drawerItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification settings coming soon'), backgroundColor: Colors.orangeAccent),
                  );
                },
              ),
              _drawerItem(
                icon: Icons.devices,
                label: 'Manage Sessions',
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen()));
                },
              ),
              _drawerItem(
                icon: Icons.delete_sweep_outlined,
                label: 'Clear Cache',
                onTap: () {
                  Navigator.pop(context);
                  _showCacheCleared(context);
                },
              ),
              _drawerItem(
                icon: Icons.info_outline,
                label: 'About',
                trailing: _appVersion != null
                    ? Text('v$_appVersion', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog(context);
                },
              ),
              const Divider(color: Colors.white12, height: 24),
              _drawerItem(
                icon: Icons.logout,
                label: 'Sign Out',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestDrawer(BuildContext context, AuthProvider auth) {
    final theme = context.watch<ThemeProvider>();

    return Drawer(
      backgroundColor: const Color(0xFF0D1117),
      width: MediaQuery.of(context).size.width * 0.78,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.person_outline_rounded, size: 32, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Guest', style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Browse as guest', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sign in to unlock:', style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
                    const SizedBox(height: 12),
                    _featureCard(Icons.favorite, 'Favorites', 'Save movies you love'),
                    _featureCard(Icons.bookmark, 'Watchlist', 'Plan what to watch next'),
                    _featureCard(Icons.history, 'History', 'Track what you\'ve watched'),
                    _featureCard(Icons.rate_review, 'Reviews', 'Rate and review movies'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => auth.exitGuestMode(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Sign In / Create Account', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 24),
              _sectionHeader('Settings'),
              _drawerItem(
                icon: theme.isDark ? Icons.light_mode : Icons.dark_mode,
                label: theme.isDark ? 'Light Mode' : 'Dark Mode',
                trailing: Switch(
                  value: !theme.isDark,
                  activeTrackColor: const Color(0xFFFFC107),
                  activeThumbColor: Colors.black,
                  inactiveTrackColor: Colors.white24,
                  inactiveThumbColor: Colors.white54,
                  onChanged: (_) => theme.toggle(),
                ),
                onTap: () => theme.toggle(),
              ),
              _drawerItem(
                icon: Icons.language,
                label: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('English', style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
                    const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
                  ],
                ),
                onTap: () => _showLanguageDialog(context),
              ),
              _drawerItem(
                icon: Icons.info_outline,
                label: 'About',
                trailing: _appVersion != null
                    ? Text('v$_appVersion', style: GoogleFonts.inter(fontSize: 11, color: Colors.white38))
                    : null,
                onTap: () => _showAboutDialog(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: color ?? Colors.white54),
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 14, color: color ?? Colors.white70),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _featureCard(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white38),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.white24)),
            ],
          ),
        ],
      ),
    );
  }
}
